//
//  CloseToolbarButton.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 27/01/2026.
//


import SwiftUI

public struct CloseToolbarButton: View {
    public let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close) {
                action()
            }
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
                    .clipShape(Circle())
            }
        }
    }
}

#Preview("CloseToolbarButton") {
    NavigationStack {
        Text("Aperçu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseToolbarButton { }
                }
            }
    }
}
