//
//  DestructiveToolbarButton.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 27/01/2026.
//

import SwiftUI

public struct DestructiveToolbarButton: View {
    public let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .destructive) {
                action()
            }
        } else {
            Button(action: action) {
                Image(systemName: "trash")
                    .clipShape(Circle())
            }
        }
    }
}

#Preview("DestructiveToolbarButton") {
    NavigationStack {
        Text("Aperçu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DestructiveToolbarButton { }
                }
            }
    }
}
