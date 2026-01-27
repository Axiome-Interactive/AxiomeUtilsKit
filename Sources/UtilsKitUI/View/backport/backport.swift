//
//  Untitled.swift
//  AxiomeUtilsKit
//
//  Created by Limagne on 23/01/2026.
//

import SwiftUI

public struct Backport<Content> {
    public let content: Content
    
    public init(_ content: Content) {
        self.content = content
    }
}

@available(iOS 14, macOS 10.15, *)
public extension View {
    var backport: Backport<Self> { Backport(self) }
}

@available(iOS 14, macOS 11, *)
public extension ToolbarContent {
    var backport: Backport<Self> { Backport(self) }
}

// MARK: iOS 26 Extensions

@available(iOS 14, macOS 12, *)
public enum BackportGlass: Equatable, Sendable {
    case regular
    case clear
    case identity
    case tinted(Color?)
    case interactive(isEnabled: Bool)
    case tintedAndInteractive(color: Color?, isEnabled: Bool)
    
    // Default convenience
    public static var regularInteractive: BackportGlass {
        .tintedAndInteractive(color: nil, isEnabled: true)
    }
}

@available(iOS 26, macOS 26, *)
extension BackportGlass {
    public var toGlass: Glass {
        switch self {
        case .regular:
            return .regular
        case .clear:
            return .clear
        case .identity:
            return .identity
        case .tinted(let color):
            return .regular.tint(color)
        case .interactive(let isEnabled):
            return .regular.interactive(isEnabled)
        case .tintedAndInteractive(let color, let isEnabled):
            return .regular.tint(color).interactive(isEnabled)
        }
    }
}

public enum BackportTabBarMinimizeBehavior: Hashable, Sendable {
    case automatic
    case onScrollDown
    case onScrollUp
    case never
}

public enum BackportSearchToolbarBehavior: Hashable, Sendable {
    case automatic
    case minimize
}

@available(iOS 26.0, macOS 26, *)
public extension BackportTabBarMinimizeBehavior {
    var toBehavior: TabBarMinimizeBehavior {
        switch self {
        case .automatic:
            return .automatic
#if os(iOS)
        case .onScrollDown:
            return .onScrollDown
        case .onScrollUp:
            return .onScrollUp
        case .never:
            return .never
#else
        default:
            return .automatic
#endif
        }
    }
}


@MainActor
@available(iOS 14, macOS 12, *)
public extension Backport where Content: View {
    @ViewBuilder func glassEffect(
        _ backportGlass: BackportGlass = .regular,
        in shape: some Shape = Capsule()
    ) -> some View {
        if #available(iOS 26.0, macOS 26, *) {
            content.glassEffect(backportGlass.toGlass, in: shape)
        } else {
            content.clipShape(shape)
        }
    }
    
    @ViewBuilder func glassEffectContainer(spacing: CGFloat? = nil) -> some View {
        if #available(iOS 26.0, macOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
    
    @ViewBuilder func glassEffectUnion(
        id: (some Hashable & Sendable)?,
        namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 26.0, macOS 26, *) {
            content.glassEffectUnion(id: id, namespace: namespace)
        } else {
            content
        }
    }
    
    @ViewBuilder func glassButtonStyle(fallbackStyle: some PrimitiveButtonStyle = DefaultButtonStyle()) -> some View {
        if #available(iOS 26.0, macOS 26, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(fallbackStyle)
        }
    }
    
    @ViewBuilder func glassProminentButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            if #available(macOS 12.0, *) {
                content.buttonStyle(.borderedProminent)
            } else {
                content
            }
        }
    }
    
    @ViewBuilder func tabViewBottomAccessory(@ViewBuilder content: () -> some View) -> some View {
#if os(macOS)
        self.content
#else
        if #available(iOS 26.0, *) {
            self.content.tabViewBottomAccessory(content: content)
        } else {
            self.content
        }
#endif
    }
    
    @ViewBuilder func tabBarMinimizeBehavior(_ behavior: BackportTabBarMinimizeBehavior) -> some View {
            if #available(iOS 26.0, macOS 26, *) {
                content.tabBarMinimizeBehavior(behavior.toBehavior)
            } else {
                content
            }
        }
}
