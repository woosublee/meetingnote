//
//  DesignSystem.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let appBackground = Color(hex: "#0D0D0D")
    static let sidebarBg = Color(hex: "#1A1A1A")
    static let cardBg = Color(hex: "#202020")
    static let cardHover = Color(hex: "#2A2A2A")
    static let appBorder = Color(hex: "#2F2F2F")
    static let appPrimary = Color(hex: "#3B82F6")
    static let primaryHover = Color(hex: "#2563EB")
    static let appSuccess = Color(hex: "#10B981")
    static let appDanger = Color(hex: "#EF4444")
    static let appWarning = Color(hex: "#F59E0B")
    static let appSecondary = Color(hex: "#6B7280")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#9CA3AF")
    static let textTertiary = Color(hex: "#6B7280")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Tokens
struct AppDesign {
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 6
    static let buttonCornerRadius: CGFloat = 6
    static let spacing: CGFloat = 12
    static let sidebarWidth: CGFloat = 176
    static let defaultPadding: CGFloat = 16
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .fill(isEnabled ? Color.appPrimary : Color.appSecondary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .fill(Color.cardBg)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .fill(Color.appDanger)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14))
            .foregroundColor(.textSecondary)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                    .fill(Color.cardBg)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}
