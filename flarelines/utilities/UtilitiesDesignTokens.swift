//
//  DesignTokens.swift
//  flarelines
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import SwiftUI

/// Design tokens for consistent styling throughout the app
enum DesignTokens {
    
    // MARK: - Colors
    enum Colors {
        static let primaryBackground = Color(UIColor.systemGroupedBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemGroupedBackground)
        static let cardBackground = Color(UIColor.systemBackground)

        static let primaryText = Color.primary
        static let secondaryText = Color.secondary

        // Accent uses highlight for better light/dark mode visibility
        static let accent = highlight
        static let accentLight = Color.gray.opacity(0.3)

        // Highlight color (tomato red #ff6347)
        static let highlight = Color(red: 1.0, green: 0.388, blue: 0.278)

        static let recordingActive = Color.red
        static let recordingBackground = Color.red.opacity(0.1)

        static let chartLine = highlight
        static let chartPoint = highlight

        // Divider color that adapts to light/dark mode
        static let divider = Color(UIColor.separator)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let huge: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    // Matches iOS Form/List insetGrouped style (12.83pt)
    enum CornerRadius {
        static let standard: CGFloat = 12.83
        static let sm: CGFloat = 12.83
        static let md: CGFloat = 12.83
        static let lg: CGFloat = 12.83
        static let xl: CGFloat = 12.83
    }
    
    // MARK: - Typography
    enum Typography {
        static let title = Font.largeTitle      // Page titles (h1)
        static let heading = Font.title2        // Section headings (h2)
        static let subheading = Font.headline   // Subsections (h3)
        static let body = Font.body             // Content text (p)
        static let caption = Font.caption       // Metadata (small)
    }

    // MARK: - Font Weight
    enum Weight {
        static let emphasis: Font.Weight = .semibold   // Headings, buttons
        static let strong: Font.Weight = .bold         // Page titles, section headers
    }

    // MARK: - Dimensions
    enum Dimensions {
        static let textEditorHeight: CGFloat = 200
        static let textEditorHeightSmall: CGFloat = 100
        static let textEditorHeightCompact: CGFloat = 80
        static let chartHeight: CGFloat = 200
        static let chartPointSize: CGFloat = 60
        static let buttonHeight: CGFloat = 48
        static let actionButtonSize: CGFloat = 56
        static let progressBarHeight: CGFloat = 4
        static let heroIconSize: CGFloat = 80
        static let contentMaxWidth: CGFloat = 300
    }
}

// MARK: - Custom View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(DesignTokens.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? DesignTokens.Colors.accent : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(DesignTokens.Colors.cardBackground)
            .foregroundColor(isEnabled ? DesignTokens.Colors.primaryText : .gray)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                    .stroke(DesignTokens.Colors.accentLight, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct QuestionCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.heading)
            .fontWeight(DesignTokens.Weight.emphasis)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.xxl)
            .background(DesignTokens.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func questionCardStyle() -> some View {
        modifier(QuestionCardStyle())
    }
}
