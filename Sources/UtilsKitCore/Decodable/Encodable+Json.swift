//
//  Encodable+json.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 08/12/2025.
//

import Foundation

extension Encodable {
    
    /**
     Return JSON represent object
     */
    public func toJson(cleanNilValues: Bool = false) -> [String: AnyObject] {
        guard
            let data = try? JSONEncoder().encode(self),
            var object = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: AnyObject] else {
            return [:]
        }
        
        if cleanNilValues {
            object = object.filter { !($0.value is NSNull) }
        }
        
        return object
    }
}
