//
//  RequestFile.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation

public struct RequestFile: Sendable {
	public let key: String
	public let name: String
	public let type: String
	public let data: Data
	
	public init(key: String, name: String, type: String, data: Data) {
		self.key = key
		self.name = name
		self.type = type
		self.data = data
	}
}
