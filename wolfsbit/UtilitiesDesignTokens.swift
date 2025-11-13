//
//  DesignTokens.swift
//  wolfsbit
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
        
        static let accent = Color.black
        static let accentLight = Color.gray.opacity(0.3)
        
        static let recordingActive = Color.red
        static let recordingBackground = Color.red.opacity(0.1)
        
        static let chartLine = Color.primary
        static let chartPoint = Color.primary
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }
    
    // MARK: - Typography
    enum Typography {
        static let questionText = Font.title2.weight(.semibold)
        static let bodyText = Font.body
        static let captionText = Font.caption
        static let headlineText = Font.headline
    }
    
    // MARK: - Dimensions
    enum Dimensions {
        static let textEditorHeight: CGFloat = 200
        static let chartHeight: CGFloat = 200
        static let buttonHeight: CGFloat = 50
        static let progressBarHeight: CGFloat = 4
    }
}

// MARK: - Custom View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(DesignTokens.Colors.cardBackground)
            .cornerRadius(DesignTokens.CornerRadius.md)
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
            .cornerRadius(DesignTokens.CornerRadius.md)
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
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(DesignTokens.Colors.accentLight, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct QuestionCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.questionText)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.xxl)
            .background(DesignTokens.Colors.accent)
            .cornerRadius(DesignTokens.CornerRadius.md)
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
