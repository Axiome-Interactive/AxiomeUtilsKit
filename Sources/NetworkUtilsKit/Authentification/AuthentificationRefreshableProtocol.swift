//
//  AuthentificationRefreshableProtocol.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol AuthentificationRefreshableProtocol: AuthentificationProtocol, Sendable {
	
	var isValid: Bool { get async }
    
	nonisolated func refresh(from request: URLRequest?) async throws
}
