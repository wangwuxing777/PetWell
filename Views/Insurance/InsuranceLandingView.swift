//
//  InsuranceLandingView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI

struct InsuranceLandingView: View {
	@State private var showCompareView = false

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					// Hero Section
					VStack(alignment: .leading, spacing: 12) {
						Text("Pet Insurance")
							.font(.system(.title, design: .default).weight(.bold))
							.foregroundStyle(.primary)

						Text("Protect Your Furry Friend's Health")
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
						Text("Why Pet Insurance?")
							.font(.system(.headline, design: .default).weight(.semibold))
							.foregroundStyle(.primary)
							.padding(.horizontal, 16)

						VStack(alignment: .leading, spacing: 12) {
							benefitCard(
								icon: "heart.fill",
								title: "Unexpected Medical Costs",
								description: "Veterinary care can be expensive. Insurance helps you afford the best treatment for your pet without financial stress."
							)

							benefitCard(
								icon: "bolt.fill",
								title: "Peace of Mind",
								description: "Focus on your pet's recovery, not the cost. Insurance gives you confidence to make the best healthcare decisions."
							)

							benefitCard(
								icon: "checkmark.circle.fill",
								title: "Comprehensive Coverage",
								description: "From accidents and illnesses to surgeries and specialist visits, we've got your pet covered."
							)

							benefitCard(
								icon: "heart.text.square.fill",
								title: "Early Protection",
								description: "Insure your pet while young to avoid pre-existing condition exclusions and get better rates."
							)
						}
						.padding(.horizontal, 16)
					}
					.padding(.vertical, 16)

					// Plans Overview
					VStack(alignment: .leading, spacing: 16) {
						Text("Our Plans")
							.font(.system(.headline, design: .default).weight(.semibold))
							.foregroundStyle(.primary)
							.padding(.horizontal, 16)

						HStack(spacing: 12) {
							planOverviewCard(
								name: "Essential",
								price: "HKD 196/mo",
								highlight: "Basic coverage",
								color: .gray
							)

							planOverviewCard(
								name: "Plus",
								price: "HKD 270/mo",
								highlight: "Maximum coverage",
								color: .blue
							)
						}
						.padding(.horizontal, 16)
					}
					.padding(.vertical, 16)

					// CTA Button
					NavigationLink(destination: InsuranceCompareView()) {
						HStack {
							Text("Compare Plans")
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
