//
//  Decodable+Decode.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 08/12/2025.
//

import Foundation

extension Decodable {
    
    /**
     A convenience method to decode data into a object compliant with `Decodable` protocol
     */
    public static func decode(from data: Any?) throws -> Self {
        
        if let data = data,
           let jsonData = (data as? Data) ?? (try? JSONSerialization.data(withJSONObject: data)) {
            do {
                let object: Self = try JSONDecoder().decode(Self.self, from: jsonData)
                return object
            } catch DecodingError.keyNotFound(let key, let context) {
                AppLogger.l("Key \"\(key.stringValue)\" not found in \(String(describing: Self.self))", level: .error)
                throw DecodingError.keyNotFound(key, context)
            } catch DecodingError.valueNotFound(let type, let context) {
                AppLogger.l("Type \"\(type)\" not found in \(String(describing: Self.self))", level: .error)
                throw DecodingError.valueNotFound(type, context)
            } catch DecodingError.typeMismatch(let type, let context) {
                AppLogger.l("\"\(type)\" not match in \(String(describing: Self.self))", level: .error)
                throw DecodingError.typeMismatch(type, context)
            } catch DecodingError.dataCorrupted(let context) {
                AppLogger.l("Data corruped in \(String(describing: Self.self))", level: .error)
                throw DecodingError.dataCorrupted(context)
            } catch let error {
                throw error
            }
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Empty data"))
        }
    }
}
