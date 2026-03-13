//
//  Double+Utils.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 24/02/2026.
//

import Foundation

extension Double {

    var metersToKm: Double {
        self / 1_000
    }

    public var asFormattedDistance: String {
        self.formatted(.number.precision(.fractionLength(2)))
    }

    public var asFormattedScale: String {
        "\(metersToKm.formatted(.number.precision(.fractionLength(2))))km"
    }

    public func roundNearMultiple(multiple: Double) -> Double {
        if self >= 0 {
            return ceil(self / multiple) * multiple
        } else {
            return floor(self / multiple) * multiple
        }
    }

    public var meters: Measurement<UnitLength> {
        Measurement(value: self, unit: .meters)
    }

    public var kilometersPerHour: Measurement<UnitSpeed> {
        Measurement(value: self, unit: .kilometersPerHour)
    }
}
