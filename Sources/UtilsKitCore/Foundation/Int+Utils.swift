//
//  Int+Utils.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 24/02/2026.
//

import Foundation

extension Int {
    public func toDouble()-> Double {
        Double(self)
    }

    public var meters: Measurement<UnitLength> {
        Measurement(value: self.toDouble(), unit: .meters)
    }

    public var kilometers: Measurement<UnitLength> {
        Measurement(value: self.toDouble(), unit: .kilometers)
    }

    public var seconds: Measurement<UnitDuration> {
        Measurement(value: self.toDouble(), unit: .seconds)
    }

    public var minutes: Measurement<UnitDuration> {
        Measurement(value: self.toDouble(), unit: .minutes)
    }

    public var kilometersPerHour: Measurement<UnitSpeed> {
        Measurement(value: self.toDouble(), unit: .kilometersPerHour)
    }

    public func roundNearMultiple(multiple: Double) -> Int {
        if self >= 0 {
            return Int(ceil(Double(self) / multiple) * multiple)
        } else {
            return Int(floor(Double(self) / multiple) * multiple)
        }
    }
}
