//
//  Theme.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-31.
//

import SwiftUI
import UIKit

extension Color {

    static let brandPrimary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.11, blue: 0.24, alpha: 1)
            : UIColor(red: 0.05, green: 0.11, blue: 0.24, alpha: 1)
    })

    static let brandSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.42, blue: 0.75, alpha: 1)
            : UIColor(red: 0.07, green: 0.23, blue: 0.50, alpha: 1)
    })

    static let brandAccent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.76, blue: 1.00, alpha: 1)
            : UIColor(red: 0.07, green: 0.28, blue: 0.58, alpha: 1)
    })

    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.07, blue: 0.16, alpha: 1)
            : UIColor.systemGroupedBackground
    })

    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 1)
            : UIColor.secondarySystemGroupedBackground
    })

    static let surfaceBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.16, blue: 0.30, alpha: 1)
            : UIColor.tertiarySystemGroupedBackground
    })

    static let statusActive   = Color(hex: "#00C48C")
    static let statusWarning  = Color(hex: "#FFB800")
    static let statusInactive = Color(hex: "#8E8E93")
    static let statusDanger   = Color(hex: "#FF453A")
    static let statusInfo     = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.76, blue: 1.00, alpha: 1)
            : UIColor(red: 0.07, green: 0.28, blue: 0.58, alpha: 1)
    })

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
            ? UIColor(white: 1, alpha: 0.40)
            : UIColor.tertiaryLabel
    })

    static let textOnBrand = Color.white

    static let textOnLight = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 0.05, green: 0.11, blue: 0.24, alpha: 1)
    })

    static let inputBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 1)
            : UIColor.secondarySystemGroupedBackground
    })

    static let divider = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.10)
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
        colors: [Color(hex: "#0D1B3E"), Color(hex: "#1A3A6B")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let brandSubtle = LinearGradient(
        colors: [Color(hex: "#0D1B3E").opacity(0.12), Color(hex: "#1A3A6B").opacity(0.06)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let brandAccentGlow = LinearGradient(
        colors: [Color(hex: "#1A3A6B"), Color(hex: "#3B82C4")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
