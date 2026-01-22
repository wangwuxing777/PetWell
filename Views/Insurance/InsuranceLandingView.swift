//
//  InsuranceLandingView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI

struct InsuranceLandingView: View {
	@EnvironmentObject var languageManager: LanguageManager
	@State private var showCompareView = false

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					// Hero Section
					VStack(alignment: .leading, spacing: 12) {
						Text(languageManager.isChinese ? "寵物保險" : "Pet Insurance")
							.font(.system(.title, design: .default).weight(.bold))
							.foregroundStyle(.primary)

						Text(languageManager.isChinese ? "守護毛孩健康" : "Protect Your Furry Friend's Health")
							.font(.system(.headline, design: .default))
							.foregroundStyle(.secondary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(16)
					.background(Color.blue.opacity(0.1))
					.cornerRadius(12)
					.padding(.horizontal, 16)
					.padding(.top, 16)

					// Why Insurance Section
					VStack(alignment: .leading, spacing: 16) {
						Text(languageManager.isChinese ? "為什麼需要寵物保險？" : "Why Pet Insurance?")
							.font(.system(.headline, design: .default).weight(.semibold))
							.foregroundStyle(.primary)
							.padding(.horizontal, 16)

						// 1. Cost of Raising a Pet Section
						VStack(alignment: .leading, spacing: 12) {
							Text(languageManager.isChinese ? "養寵物的真實成本" : "The Real Cost of Pet Parenthood")
								.font(.subheadline)
								.fontWeight(.bold)
								.foregroundColor(.secondary)
							
							HStack(spacing: 16) {
								costCard(petType: languageManager.isChinese ? "狗" : "Dog", lifetimeCost: "$650k+", monthlyAvg: "~$20k/yr")
								costCard(petType: languageManager.isChinese ? "貓" : "Cat", lifetimeCost: "$500k+", monthlyAvg: "~$12.5k/yr")
							}
							
							VStack(alignment: .leading, spacing: 8) {
								HStack(alignment: .top) {
									Image(systemName: "exclamationmark.triangle.fill")
										.foregroundColor(.orange)
									Text(languageManager.isChinese ? "意外手術費可達 HKD 30,000 - 100,000+" : "Unexpected surgeries can cost HKD 30,000 - 100,000+")
										.font(.caption)
										.fontWeight(.medium)
								}
								HStack(alignment: .top) {
									Image(systemName: "chart.line.uptrend.xyaxis")
										.foregroundColor(.blue)
									Text(languageManager.isChinese ? "醫療通脹逐年上升" : "Medical inflation is rising every year.")
										.font(.caption)
										.fontWeight(.medium)
								}
								Text("Source: OneDegree & Market Analysis (2025)")
									.font(.system(size: 10))
									.foregroundColor(.gray)
									.padding(.top, 4)
							}
							.padding()
							.background(Color.white)
							.cornerRadius(8)
							.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

						}
						.padding(16)
						.background(Color(.systemGray6))
						.cornerRadius(12)
						.padding(.horizontal, 16)

						VStack(alignment: .leading, spacing: 12) {
							benefitCard(
								icon: "heart.fill",
								title: languageManager.isChinese ? "意外醫療費用" : "Unexpected Medical Costs",
								description: languageManager.isChinese ? "獸醫費用高昂，保險助您減輕負擔，給予寵物最佳治療。" : "Veterinary care can be expensive. Insurance helps you afford the best treatment for your pet without financial stress."
							)

							benefitCard(
								icon: "bolt.fill",
								title: languageManager.isChinese ? "安心無憂" : "Peace of Mind",
								description: languageManager.isChinese ? "專注寵物康復，無需擔憂費用。保險給您信心做最佳醫療決策。" : "Focus on your pet's recovery, not the cost. Insurance gives you confidence to make the best healthcare decisions."
							)

							benefitCard(
								icon: "checkmark.circle.fill",
								title: languageManager.isChinese ? "全面保障" : "Comprehensive Coverage",
								description: languageManager.isChinese ? "從意外受傷到疾病手術，我們為您的寵物提供全面保障。" : "From accidents and illnesses to surgeries and specialist visits, we've got your pet covered."
							)

							benefitCard(
								icon: "heart.text.square.fill",
								title: languageManager.isChinese ? "及早投保" : "Early Protection",
								description: languageManager.isChinese ? "趁年輕投保，避免既有病症不保，並享受更優惠保費。" : "Insure your pet while young to avoid pre-existing condition exclusions and get better rates."
							)
						}
						.padding(.horizontal, 16)
					}
					.padding(.vertical, 16)

					// Plans Overview
					VStack(alignment: .leading, spacing: 16) {
						Text(languageManager.isChinese ? "精選計劃" : "Our Plans")
							.font(.system(.headline, design: .default).weight(.semibold))
							.foregroundStyle(.primary)
							.padding(.horizontal, 16)

						HStack(spacing: 12) {
							planOverviewCard(
								name: languageManager.isChinese ? "基本計劃" : "Essential",
								price: "HKD 196/mo",
								highlight: languageManager.isChinese ? "基本保障" : "Basic coverage",
								color: .gray
							)

							planOverviewCard(
								name: languageManager.isChinese ? "升級計劃" : "Plus",
								price: "HKD 270/mo",
								highlight: languageManager.isChinese ? "最高保障" : "Maximum coverage",
								color: .blue
							)
						}
						.padding(.horizontal, 16)
					}
					.padding(.vertical, 16)

					// CTA Button
					NavigationLink(destination: InsuranceCompareView()) {
						HStack {
							Text(languageManager.isChinese ? "比較計劃" : "Compare Plans")
								.font(.system(.body, design: .default).weight(.semibold))
								.foregroundStyle(.white)

							Image(systemName: "arrow.right")
								.foregroundStyle(.white)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(Color.blue)
						.cornerRadius(8)
					}
					.padding(.horizontal, 16)
					.padding(.bottom, 32)
				}
			}
			.navigationTitle("Insurance")
			.navigationBarTitleDisplayMode(.inline)
		}
	}

	@ViewBuilder
	private func costCard(petType: String, lifetimeCost: String, monthlyAvg: String) -> some View {
		VStack(spacing: 6) {
			Text(petType)
				.font(.headline)
			Text(lifetimeCost)
				.font(.title3)
				.fontWeight(.bold)
				.foregroundColor(.blue)
			Text("Lifetime Est.")
				.font(.caption2)
				.foregroundColor(.gray)
			Divider()
			Text(monthlyAvg)
				.font(.caption)
				.fontWeight(.semibold)
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(Color.white)
		.cornerRadius(10)
		.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
	}

	private func benefitCard(icon: String, title: String, description: String) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: icon)
				.font(.system(.body, design: .default).weight(.semibold))
				.foregroundStyle(.blue)
				.frame(width: 24)

			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(.body, design: .default).weight(.semibold))
					.foregroundStyle(.primary)

				Text(description)
					.font(.system(.caption, design: .default))
					.foregroundStyle(.secondary)
					.lineLimit(3)
			}

			Spacer()
		}
		.padding(12)
		.background(Color(.systemGray6))
		.cornerRadius(8)
	}

	private func planOverviewCard(name: String, price: String, highlight: String, color: Color) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(name)
				.font(.system(.body, design: .default).weight(.semibold))
				.foregroundStyle(.primary)

			Text(price)
				.font(.system(.headline, design: .default).weight(.bold))
				.foregroundStyle(color)

			Text(highlight)
				.font(.system(.caption, design: .default))
				.foregroundStyle(.secondary)

			Spacer()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.frame(height: 120)
		.padding(12)
		.background(Color(.systemGray6))
		.cornerRadius(8)
	}
}

#Preview {
	InsuranceLandingView()
}
