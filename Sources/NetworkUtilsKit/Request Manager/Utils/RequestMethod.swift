//
//  RequestMethod.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 05/01/2026.
//

import Foundation

public enum RequestMethod: String, Sendable {
    case connect 	= "CONNECT"
    case delete  	= "DELETE"
    case get 		= "GET"
    case head		= "HEAD"
    case options	= "OPTIONS"
    case patch		= "PATCH"
    case post		= "POST"
    case put		= "PUT"
    case trace		= "TRACE"
    case update		= "UPDATE"
}
