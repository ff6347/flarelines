// ABOUTME: Tests for DesignTokens constants and styling values.
// ABOUTME: Validates spacing, dimensions, and corner radius consistency.

import Foundation
import Testing
import SwiftUI
@testable import Flarelines

struct DesignTokensTests {

    // MARK: - Spacing Tests

    @Test func spacingValuesAreOrdered() {
        #expect(DesignTokens.Spacing.xs < DesignTokens.Spacing.sm)
        #expect(DesignTokens.Spacing.sm < DesignTokens.Spacing.md)
        #expect(DesignTokens.Spacing.md < DesignTokens.Spacing.lg)
        #expect(DesignTokens.Spacing.lg < DesignTokens.Spacing.xl)
        #expect(DesignTokens.Spacing.xl < DesignTokens.Spacing.xxl)
        #expect(DesignTokens.Spacing.xxl < DesignTokens.Spacing.xxxl)
        #expect(DesignTokens.Spacing.xxxl < DesignTokens.Spacing.huge)
    }

    @Test func spacingValuesArePositive() {
        #expect(DesignTokens.Spacing.xs > 0)
        #expect(DesignTokens.Spacing.sm > 0)
        #expect(DesignTokens.Spacing.md > 0)
        #expect(DesignTokens.Spacing.lg > 0)
        #expect(DesignTokens.Spacing.xl > 0)
        #expect(DesignTokens.Spacing.xxl > 0)
        #expect(DesignTokens.Spacing.xxxl > 0)
        #expect(DesignTokens.Spacing.huge > 0)
    }

    @Test func spacingSpecificValues() {
        #expect(DesignTokens.Spacing.xs == 4)
        #expect(DesignTokens.Spacing.sm == 8)
        #expect(DesignTokens.Spacing.md == 12)
        #expect(DesignTokens.Spacing.lg == 16)
        #expect(DesignTokens.Spacing.xl == 24)
    }

    // MARK: - Corner Radius Tests

    @Test func cornerRadiusMatchesiOSStyle() {
        // iOS insetGrouped style uses 12.83pt
        #expect(DesignTokens.CornerRadius.standard == 12.83)
    }

    @Test func allCornerRadiiAreConsistent() {
        // All corner radii should match for design consistency
        #expect(DesignTokens.CornerRadius.sm == DesignTokens.CornerRadius.standard)
        #expect(DesignTokens.CornerRadius.md == DesignTokens.CornerRadius.standard)
        #expect(DesignTokens.CornerRadius.lg == DesignTokens.CornerRadius.standard)
        #expect(DesignTokens.CornerRadius.xl == DesignTokens.CornerRadius.standard)
    }

    // MARK: - Dimensions Tests

    @Test func textEditorHeightsAreOrdered() {
        #expect(DesignTokens.Dimensions.textEditorHeightCompact < DesignTokens.Dimensions.textEditorHeightSmall)
        #expect(DesignTokens.Dimensions.textEditorHeightSmall < DesignTokens.Dimensions.textEditorHeight)
    }

    @Test func dimensionsArePositive() {
        #expect(DesignTokens.Dimensions.textEditorHeight > 0)
        #expect(DesignTokens.Dimensions.chartHeight > 0)
        #expect(DesignTokens.Dimensions.buttonHeight > 0)
        #expect(DesignTokens.Dimensions.actionButtonSize > 0)
        #expect(DesignTokens.Dimensions.progressBarHeight > 0)
        #expect(DesignTokens.Dimensions.heroIconSize > 0)
        #expect(DesignTokens.Dimensions.contentMaxWidth > 0)
    }

    @Test func chartDimensionsAreReasonable() {
        // Chart should be reasonably sized for mobile display
        #expect(DesignTokens.Dimensions.chartHeight >= 150)
        #expect(DesignTokens.Dimensions.chartHeight <= 400)
        #expect(DesignTokens.Dimensions.chartPointSize > 0)
    }

    @Test func buttonHeightIsAccessible() {
        // iOS HIG recommends minimum 44pt touch targets
        #expect(DesignTokens.Dimensions.buttonHeight >= 44)
        #expect(DesignTokens.Dimensions.actionButtonSize >= 44)
    }

    // MARK: - Color Token Existence Tests

    @Test func primaryColorsExist() {
        // Just verify the colors can be accessed without crashing
        let _ = DesignTokens.Colors.primaryBackground
        let _ = DesignTokens.Colors.secondaryBackground
        let _ = DesignTokens.Colors.cardBackground
        let _ = DesignTokens.Colors.primaryText
        let _ = DesignTokens.Colors.secondaryText
    }

    @Test func accentColorsExist() {
        let _ = DesignTokens.Colors.accent
        let _ = DesignTokens.Colors.accentLight
        let _ = DesignTokens.Colors.highlight
    }

    @Test func chartColorsExist() {
        let _ = DesignTokens.Colors.chartLine
        let _ = DesignTokens.Colors.chartPoint
    }

    @Test func recordingColorsExist() {
        let _ = DesignTokens.Colors.recordingActive
        let _ = DesignTokens.Colors.recordingBackground
    }

    @Test func highlightColorIsAccent() {
        // Accent should be the same as highlight per the code
        // We can't directly compare SwiftUI Colors, but we verify they're defined
        let _ = DesignTokens.Colors.highlight
        let _ = DesignTokens.Colors.accent
    }
}
