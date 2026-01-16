//
//  InsuranceCompareView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI
import Foundation

// MARK: - Data Models

struct InsuranceCompany: Identifiable, Hashable {
	let id: Int
	let nameEn: String
	let nameZh: String?
	let brandType: String
	let website: String?
	let contactPhone: String?
	let logoUrl: String?
	let logoBase64: String?
	let notes: String?

	var displayName: String {
		nameZh ?? nameEn
	}
}

struct InsuranceProduct: Identifiable, Hashable {
	let id: Int
	let companyId: Int
	let nameEn: String
	let nameZh: String?
	let description: String?
	let targetSegment: String?
	let isActive: Int
	let notes: String?

	var displayName: String {
		nameZh ?? nameEn
	}
}

struct ProductCoverageProfile: Identifiable {
	let id: Int
	let productId: Int
	let typicalSurgeryCovered: Int?
	let chronicIllnessSupported: Int?
	let coverageVsCostNotes: String?
	let annualLimitAmount: Int?
	let hasSubLimits: Int?
	let subLimitStructure: String?
	let noSubLimitMarketingTag: Int?
	let chronicMultiYearLimit: String?
	let preexistingExcluded: Int?
	let hereditaryDiseasePolicy: String?
	let breedAgeRestrictions: String?
	let waitingPeriodDescription: String?
	let inpatientSurgeryIncluded: Int?
	let exclusionsNotes: String?
	let typicalMonthlyPremium: Int?
	let reimbursementPercent: Int?
	let hasDeductible: Int?
	let deductibleAmount: Int?
	let copayPercent: Int?
	let priceValueNotes: String?
	let onlineClaimSupported: Int?
	let claimProcessSpeedNote: String?
	let claimConvenienceNotes: String?
	let brandReputationSummary: String?
	let reviewSourceNotes: String?
}

struct InsurancePlan: Identifiable, Hashable {
	let id: Int
	let productId: Int
	let name: String
	let annualLimitAmount: Int?
	let reimbursementPercent: Int?
	let hasSubLimits: Int?
	let subLimitStructure: String?
	let typicalMonthlyPremium: Int?
	let notes: String?
}

// MARK: - Main View

struct InsuranceCompareView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Mock selection for now as per "one page compare 2 insurance"
    // Ideally these would be passed in or selected via a picker
    @State private var leftPlanName: String = "Bowtie"
    @State private var rightPlanName: String = "OneDegree"
    
    // Hardcoded plan IDs or model references if strictly following DB
    // e.g. let plans = [plan1, plan2]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("insurance")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("compare insurance")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.trailing, 80) // Visual centering adjustment
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // Header Section with Plan Names and Change Buttons
                        HStack(alignment: .top, spacing: 0) {
                            // Left Plan
                            VStack(spacing: 12) {
                                Text(leftPlanName)
                                    .font(.system(size: 15, weight: .black)) // Extra bold
                                    .foregroundColor(.black)
                                
                                Button(action: {
                                    // Action to change insurer
                                    // Could show a picker here
                                }) {
                                    Text("change insurer")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color(hex: "D9D9D9")) // Design color
                                        .cornerRadius(20)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Vertical Separator
                             Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 62)
                            
                            // Right Plan
                            VStack(spacing: 12) {
                                Text(rightPlanName)
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(.black)
                                
                                Button(action: {
                                    // Action to change insurer
                                }) {
                                    Text("change insurer")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color(hex: "D9D9D9"))
                                        .cornerRadius(20)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .background(Color(hex: "F5F5F5")) // Top background bar color from design
                        
                        // Annual Limit Row
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Annual Limit")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(Color(hex: "7E7E7E"))
                                
                                Text("Max total coverage per year")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "8E8D93"))
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                            
                            HStack(spacing: 0) {
                                Text("HKD 60,000")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                
                                Rectangle()
                                    .fill(Color(hex: "E5E5E5")) // Light gray separator
                                    .frame(width: 1, height: 55)
                                
                                Text("HKD 80,000")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.bottom, 24)
                        }
                        
                        // Horizontal divider
                        Rectangle()
                            .fill(Color(hex: "E5E5E5"))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                        
                        // Property 1 (Surgery)
                        comparisonPropertyRow(
                            title: "Surgery",
                            leftIcon: "checkmark.circle.fill",
                            rightIcon: "checkmark.circle.fill", // Both true in mock
                            leftColor: .green,
                            rightColor: .green
                        )
                        
                        // Horizontal divider
                        Rectangle()
                            .fill(Color(hex: "E5E5E5"))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                        
                        // Property 2 (Overnight Hospitalization)
                        comparisonPropertyRow(
                            title: "Overnight Hospitalization",
                            leftIcon: "checkmark.circle.fill", // Mock
                            rightIcon: "checkmark.circle.fill",
                            leftColor: .green,
                            rightColor: .green
                        )
                        
                        // Horizontal divider
                        Rectangle()
                            .fill(Color(hex: "E5E5E5"))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                        
                        // Property 3 (X-Ray & Ultrasound)
                        comparisonPropertyRow(
                            title: "X-Ray & Ultrasound",
                            leftIcon: "checkmark.circle.fill", // Mock
                            rightIcon: "xmark.circle.fill", // Mock difference
                            leftColor: .green,
                            rightColor: .red
                        )
                        
                         // Horizontal divider
                        Rectangle()
                            .fill(Color(hex: "E5E5E5"))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Helper View for Property Rows
    @ViewBuilder
    private func comparisonPropertyRow(title: String, leftIcon: String, rightIcon: String, leftColor: Color, rightColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(Color(hex: "7E7E7E")) // Design color
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            
            HStack(spacing: 0) {
                Image(systemName: leftIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60) // Larger icons from design
                    .foregroundColor(leftColor) // Green for check?
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color(hex: "E5E5E5"))
                    .frame(width: 1, height: 55)
                
                Image(systemName: rightIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(rightColor)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 40) // Indent icons slightly
        }
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    InsuranceCompareView()
}

