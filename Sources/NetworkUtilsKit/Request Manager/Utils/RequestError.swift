//
//  RequestError.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation

// MARK: - Network error Enum
public enum RequestError: Error, LocalizedError {
	case url, json, emptyCache
	
	/// Request status code
	internal var statusCode: Int? {
		switch self {
		case .url, .json: return 400
		case .emptyCache: return 404
		}
	}
	
	public var errorDescription: String? {
		switch self {
		case .url: return "Invalid URL"
		case .json: return "Invalid JSON"
		case .emptyCache: return "Empty cache"
		}
	}
}
