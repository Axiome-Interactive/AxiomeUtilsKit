//
//  JSONValue.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 06/01/2026.
//

public enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        // First, try single value container types
        let single = try? decoder.singleValueContainer()

        if single?.decodeNil() == true {
            self = .null
            return
        }
        if let b = try? single?.decode(Bool.self) {
            self = .bool(b)
            return
        }
        if let n = try? single?.decode(Double.self) {
            self = .number(n)
            return
        }
        if let s = try? single?.decode(String.self) {
            self = .string(s)
            return
        }

        // Try array
        if var unkeyed = try? decoder.unkeyedContainer() {
            var arr: [JSONValue] = []
            while !unkeyed.isAtEnd {
                let value = try unkeyed.decode(JSONValue.self)
                arr.append(value)
            }
            self = .array(arr)
            return
        }

        // Try object
        if let keyed = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
            var dict: [String: JSONValue] = [:]
            for key in keyed.allKeys {
                dict[key.stringValue] = try keyed.decode(JSONValue.self, forKey: key)
            }
            self = .object(dict)
            return
        }

        // Fallback
        self = .null
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
}
