//
//  Parameters.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation

public enum Parameters: Sendable {
	case encodable(any Encodable & Sendable)
	case formURLEncoded([String: any Sendable])
	case formData([String: any Sendable])
	case other(type: (key: String, value: String), data: Data)
}
