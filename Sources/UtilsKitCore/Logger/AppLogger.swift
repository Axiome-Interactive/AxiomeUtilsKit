//
//  Log.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 08/12/2025.
//

import Foundation
import OSLog

struct AppLogger {
    enum Level: String, RawRepresentable {
        case info
        case warning
        case error
        case debug
    }
    
    enum Category {
        case `default`
        case WS(String)
        case View(String)
        case UC(String)
    }
    
    private static let instance = AppLogger()
    
    private let subsystem: String
    
    init() {
        self.subsystem = Bundle.main.bundleIdentifier!
    }
    
    func logger(category: Category = .default) -> Logger {
        return Logger(subsystem: subsystem, category: category.description)
    }
    
    static func l( _ message: String, level: Level, category: Category = .default) {
        let logger = instance.logger(category: category)
        
        switch level {
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .debug:
            logger.trace("\(message)")
        }
    }
}

extension AppLogger.Category {
    var description: String {
        switch self {
        case .default:
            "App"
        case .WS(let ws):
            "WS::\(ws)"
        case .View(let view):
            "VIEW::\(view)"
        case .UC(let useCase):
            "UC::\(useCase)"
        }
    }
}
