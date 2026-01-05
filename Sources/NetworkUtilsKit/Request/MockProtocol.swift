//
//  MockProtocol.swift
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

/// This protocol represents a mocked request to execute
public protocol MockProtocol: RequestProtocol {
	
	/// Mock file if needed
	var mockFileURL: URL? { get }
}

extension RequestProtocol where Self: MockProtocol {
	
	// MARK: Mock
	/**
	 Send request and return mocked response or error
	 */
	nonisolated public func mock() async throws -> NetworkResponse {
		guard let mockPath = self.mockFileURL else {
			AppLogger.l("Mock file not found: \(self.description) - \(ResponseError.noMock.localizedDescription)", level: .error, category: .Network(.mock))
			throw ResponseError.noMock
		}

		do {
			let data = try Data(contentsOf: mockPath, options: .mappedIfSafe)
			AppLogger.l("Mock loaded: \(self.description)", level: .info, category: .Network(.mock))
			return (200, data)
		} catch {
			AppLogger.l("Mock failed: \(self.description) - \(error.localizedDescription)", level: .error, category: .Network(.mock))
			throw error
		}
	}
	
	/**
	 Get the mocked decoded response of type `T`with progress
	 */
	nonisolated public func mock<T: Decodable>(_ type: T.Type) async throws -> T {
		
		let response = try await self.mock()
		
		guard let data = response.data else { throw ResponseError.data }
		
		do {
			return try T.decode(from: data)
		} catch {
			let responseError = ResponseError.decodable(type: "\(T.self)")
			AppLogger.l("Mock decode failed: \(self.description)", level: .error, category: .Network(.requestFail))
			throw responseError
		}
	}
}
