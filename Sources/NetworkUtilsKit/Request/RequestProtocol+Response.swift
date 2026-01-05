//
//  RequestProtocol+Response.swift
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


// MARK: Response
extension RequestProtocol {
	/**
	 Send request and return response or error, with progress value
	 */
	nonisolated public func response() async throws -> NetworkResponse {
		if let cacheKey = self.cacheKey {
			switch cacheKey.type {
			case .returnCacheDataElseLoad:
				if let data = NetworkCache.shared.get(cacheKey) {
					AppLogger.l("Cache hit: \(cacheKey.key)", level: .info, category: .Network(.cache))
					return (statusCode: 200, data: data)
				}
				
			case .returnCacheDataDontLoad:
				if let data = NetworkCache.shared.get(cacheKey) {
					AppLogger.l("Cache hit: \(cacheKey.key)", level: .info, category: .Network(.cache))
					return (statusCode: 200, data: data)
				} else {
					AppLogger.l("Cache miss: \(cacheKey.key) - \(RequestError.emptyCache.localizedDescription)", level: .error, category: .Network(.cache))
					throw RequestError.emptyCache
				}
				
			default:
				break
			}
		}
		
		do {
			await self.authentification?.refreshIfNeeded(from: nil)
			
			let response = try await RequestManager.shared.request(self)
			if let cacheKey = self.cacheKey {
				NetworkCache.shared.set(response.data, for: cacheKey)
			}
			return response
		} catch {
			if let cacheKey = self.cacheKey, let data = NetworkCache.shared.get(cacheKey) {
				AppLogger.l("Cache fallback: \(cacheKey.key)", level: .info, category: .Network(.cache))
				return (statusCode: (error as? RequestError)?.statusCode,
						data: data)
			} else {
				throw error
			}
		}
	}
	
	/**
	 Get the decoded response of type `T` with progress
	 */
	nonisolated public func response<T: Decodable>(_ type: T.Type) async throws -> T {
		let response = try await self.response()
		
		guard
			let data = response.data
		else {
			throw ResponseError.data
		}
		
		do {
			let objects = try T.decode(from: data)
			return objects
		} catch {
			AppLogger.l("Decode failed: \(self.description)", level: .error, category: .Network(.requestFail))
			throw error
		}
	}
	
	// MARK: Send
	/**
	 Send request and return  error if failed
	 */
	nonisolated public func send() async throws {
		_ = try await self.response()
	}
}
