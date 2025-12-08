//
//  View+modifier.swift
//  AxiomeUtilsKit
//
//  Created by Valentin Limagne on 08/12/2025.
//

import SwiftUI

extension View {
    @ViewBuilder public func `if`<Content: View> (_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder public func ifOptionalObject<Content: View, T> (_ optionnal: T?, transform: (T, Self) -> Content) -> some View {
        if let nonOptionnal = optionnal {
            transform(nonOptionnal, self)
        } else {
            self
        }
    }

}
