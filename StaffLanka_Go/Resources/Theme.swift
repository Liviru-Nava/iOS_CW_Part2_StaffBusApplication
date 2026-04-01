//
//  Theme.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-31.
//

import SwiftUI
import UIKit

extension Color {
    static let brandPrimary = Color(hex: "#0A5568")
    static let brandSecondary = Color(hex: "#1A8FAA")
    static let brandAccent = Color(hex: "#FFB800")

    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.20, blue: 0.25, alpha: 1)
            : UIColor.systemBackground
    })

    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.25, blue: 0.31, alpha: 1)
            : UIColor.secondarySystemBackground
    })

    static let surfaceBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.30, blue: 0.37, alpha: 1)
            : UIColor.tertiarySystemBackground
    })

    static let statusActive = Color(hex: "#00C48C")
    static let statusWarning = Color(hex: "#FFB800")
    static let statusInactive = Color(hex: "#8E8E93")
    static let statusDanger = Color(hex: "#FF453A")
    static let statusInfo = Color(hex: "#0A84FF")

    static let textPrimary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.label
    })

    static let textSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.65)
            : UIColor.secondaryLabel
    })

    static let textTertiary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.4)
            : UIColor.tertiaryLabel
    })

    static let textOnBrand = Color.white

    static let inputBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.25, blue: 0.31, alpha: 1)
            : UIColor.secondarySystemBackground
    })

    static let divider = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.12)
            : UIColor.separator
    })

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let int = UInt64(hex, radix: 16) ?? 0
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let brandSubtle = LinearGradient(
        colors: [Color(hex: "#0A5568").opacity(0.1), Color(hex: "#1A8FAA").opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
