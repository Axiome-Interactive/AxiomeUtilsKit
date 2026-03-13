//
//  RequestManager+Request.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation
import OSLog

#if canImport(UtilsKitCore)
import UtilsKitCore
#endif

#if canImport(UtilsKit)
import UtilsKit
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Request
extension RequestManager {
    
    //swiftlint:disable closure_body_length
    //swiftlint:disable function_body_length
    private func request(scheme: String,
                         host: String,
                         path: String,
                         port: Int?,
                         warningTime: Double,
                         method: RequestMethod = .get,
                         urlParameters: [String: String]?,
                         parameters: Parameters?,
                         files: [RequestFile]?,
                         headers: Headers?,
                         authentification: AuthentificationProtocol?,
                         timeout: TimeInterval?,
                         description: String,
                         retryAuthentification: Bool,
                         cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async throws -> NetworkResponse {
        
        // Request
        var request: URLRequest = try await self.buildRequest(scheme: scheme,
                                                              host: host,
                                                              path: path,
                                                              port: port,
                                                              method: method,
                                                              urlParameters: urlParameters,
                                                              parameters: parameters,
                                                              files: files,
                                                              headers: headers,
                                                              authentification: authentification,
                                                              timeout: timeout,
                                                              cachePolicy: cachePolicy)
        
        request.timeoutInterval = timeout ?? self.requestTimeoutInterval
        
        AppLogger.l("Request sent: \(description)", level: .info, category: .Network(.requestSend))
        
        // Date
        let startDate = Date.now
        let session = URLSession(configuration: self.requestConfiguration)
        session.configuration.timeoutIntervalForRequest = timeout ?? self.requestTimeoutInterval
        let requestTask = Task {
            try await session.data(for: request)
        }
        let requestTaskID = self.register(task: requestTask, for: description)
        
        do {
            // Call
            let (data, response) = try await withTaskCancellationHandler {
                try await requestTask.value
            } onCancel: {
                requestTask.cancel()
            }
            
            self.unregisterTask(for: description, taskID: requestTaskID)
            
            // Time
            let time = Date.now.timeIntervalSince(startDate)
            let requestId = "\(description) - \(time.formatted(.number.precision(.fractionLength(3))))s"
            
            // Response
            guard let response = response as? HTTPURLResponse else { throw ResponseError.unknow }
            
            if response.statusCode >= 200 && response.statusCode < 300 {
                if time > warningTime {
                    AppLogger.l("Request success (slow): \(requestId)", level: .warning, category: .Network(.requestSuccess))
                } else {
                    AppLogger.l("Request success: \(requestId)", level: .info, category: .Network(.requestSuccess))
                }
                return (response.statusCode, data)
            } else if response.statusCode == 401 && retryAuthentification {
                let error = self.returnError(requestId: requestId,
                                             response: response,
                                             data: data)
                
                var refreshArray: [any AuthentificationRefreshableProtocol] = []
                
                if let refreshAuthent = authentification as? any AuthentificationRefreshableProtocol {
                    refreshArray = [refreshAuthent]
                } else if let authentificationArray = (authentification as? [any AuthentificationProtocol])?
                    .compactMap({ $0 as? any AuthentificationRefreshableProtocol }) {
                    refreshArray = authentificationArray
                }
                
                if refreshArray.isEmpty {
                    throw error
                }
                
                try await self.refresh(authentification: refreshArray,
                                       requestId: requestId,
                                       request: request)
                
                return try await self.request(scheme: scheme,
                                              host: host,
                                              path: path,
                                              port: port,
                                              warningTime: warningTime,
                                              method: method,
                                              urlParameters: urlParameters,
                                              parameters: parameters,
                                              files: files,
                                              headers: headers,
                                              authentification: authentification,
                                              timeout: timeout,
                                              description: description,
                                              retryAuthentification: false,
                                              cachePolicy: cachePolicy)
            } else {
                throw self.returnError(requestId: requestId,
                                       response: response,
                                       data: data)
            }
        } catch {
            self.unregisterTask(for: description, taskID: requestTaskID)
            AppLogger.l("Request failed: \(description) - \(error.localizedDescription)", level: .error, category: .Network(.requestFail))
            throw error
        }
    }
    
    private func refresh(authentification: [any AuthentificationRefreshableProtocol],
                         requestId: String,
                         request: URLRequest) async throws {
        guard let first = authentification.first else {
            return
        }
        
        try await first.refresh(from: request)
        try await refresh(authentification: Array(authentification.dropFirst()),
                          requestId: requestId,
                          request: request)
    }
    
    private func returnError(requestId: String,
                             response: HTTPURLResponse,
                             data: Data?) -> Error  {
        let error = ResponseError.network(response: response, data: data)
        AppLogger.l("Request error: \(requestId) - \(error.localizedDescription)", level: .error, category: .Network(.requestFail))
        return error
    }
    
    /**
     Send request
     - parameter request: Request
     - parameter result: Request Result
     */
    public func request(_ request: RequestProtocol) async throws -> NetworkResponse {
        try await self.request(scheme: request.scheme,
                               host: request.host,
                               path: request.path,
                               port: request.port,
                               warningTime: request.warningTime,
                               method: request.method,
                               urlParameters: request.urlParameters,
                               parameters: request.parameters,
                               files: request.files,
                               headers: request.headers,
                               authentification: request.authentification,
                               timeout: request.timeoutInterval,
                               description: request.description,
                               retryAuthentification: request.canRefreshToken,
                               cachePolicy: request.cachePolicy)
    }
}
