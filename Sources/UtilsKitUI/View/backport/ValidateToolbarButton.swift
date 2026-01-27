//
//  ValidateToolbarButton.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 27/01/2026.
//

import SwiftUI

public struct ValidateToolbarButton: View {
    public let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .confirm) {
                action()
            }
        } else {
            Button(action: action) {
                Image(systemName: "checkmark")
                    .clipShape(Circle())
            }
            .tint(.blue)
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("ValidateToolbarButton") {
    NavigationStack {
        Text("Aperçu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ValidateToolbarButton { }
                }
            }
    }
}
