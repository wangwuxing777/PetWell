//
//  AppTheme.swift
//  PetWell
//
//  Semantic color layer for Dark Mode support.
//  All views MUST use these tokens instead of Color.white / Color.black / hex constants.
//  Tokens are backed by Asset Catalog color sets that provide Any + Dark appearances.
//

import SwiftUI

enum AppTheme {

    // MARK: - Background
    /// Page main background  Light: #F7F8FA  Dark: #0F1115
    static let bgBase      = Color("PW/bg/base")
    /// Navigation bar / grouped sections  Light: #FFFFFF  Dark: #161A22
    static let bgElevated  = Color("PW/bg/elevated")
    /// Card background  Light: #FFFFFF  Dark: #1C2230
    static let bgCard      = Color("PW/bg/card")
    /// Input / search field background  Light: #F1F3F7  Dark: #202838
    static let bgInput     = Color("PW/bg/input")

    // MARK: - Text
    /// Primary headings & body  Light: #111827  Dark: #F3F4F6
    static let textPrimary   = Color("PW/text/primary")
    /// Secondary / caption text  Light: #6B7280  Dark: #A3ADC2
    static let textSecondary = Color("PW/text/secondary")
    /// Text on brand-primary buttons  Light: #FFFFFF  Dark: #0B0D12
    static let textInverse   = Color("PW/text/inverse")

    // MARK: - Border
    /// Dividers & subtle outlines  Light: #E5E7EB  Dark: #2B3548
    static let borderSubtle = Color("PW/border/subtle")

    // MARK: - Brand
    /// Primary brand blue  Light: #2D6BFF  Dark: #4A7DFF
    static let brandPrimary = Color("PW/brand/primary")

    // MARK: - State
    /// Success  Light: #10B981  Dark: #34D399
    static let success = Color("PW/state/success")
    /// Warning  Light: #F59E0B  Dark: #FBBF24
    static let warning = Color("PW/state/warning")
    /// Error  Light: #EF4444  Dark: #F87171
    static let error   = Color("PW/state/error")
}

// MARK: - Convenience ViewModifiers

extension View {
    /// Apply the standard card style: bgCard background + subtle border + corner radius
    func pwCardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(AppTheme.bgCard)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
            )
    }

    /// Apply page-level background color
    func pwPageBackground() -> some View {
        self.background(AppTheme.bgBase.ignoresSafeArea())
    }
}
