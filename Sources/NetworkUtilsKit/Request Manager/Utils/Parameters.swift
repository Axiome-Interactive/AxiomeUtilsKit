//
//  Parameters.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation

public enum Parameters: Sendable {
	case encodable(Encodable & Sendable)
	case formURLEncoded([String: Sendable])
	case formData([String: Sendable])
	case other(type: (key: String, value: String), data: Data)
}
