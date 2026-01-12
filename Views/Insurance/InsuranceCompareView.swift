//
//  InsuranceCompareView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//


import SwiftUI
import SwiftData

struct InsuranceCompareView: View {
	struct FeatureRow: Identifiable {
		let id = UUID()
		let feature: String
		let essential: String
		let plus: String
	}

	@State private var selectedPlans: Set<String> = ["Essential", "Plus"]

	private let essentialPlan = (
		name: "Essential",
		badge: "1st year: 25% off",
		monthlyPrice: "HKD 196",
		monthlyPriceSmall: "/mo",
		annualPrice: "HKD 262/mo",
		annualPriceSmall: "HKD 2,352/yr"
	)

	private let plusPlan = (
		name: "Plus",
		badge: "1st year: 25% off",
		monthlyPrice: "HKD 270",
		monthlyPriceSmall: "/mo",
		annualPrice: "HKD 361/mo",
		annualPriceSmall: "HKD 3,240/yr"
	)

	private let features: [FeatureRow] = [
		.init(feature: "Annual Coverage", essential: "HKD 30,000", plus: "HKD 50,000"),
		.init(feature: "Reimbursement Rate", essential: "✓", plus: "✓"),
		.init(feature: "Insured age at Age 1 or above: Network Clinic 90%; Non-Network Clinic 70%, 13 weeks to 11 months; All HK registered vets 50%", essential: "✓", plus: "✓"),
		.init(feature: "Surgery", essential: "✓", plus: "✓"),
		.init(feature: "Overnight Hospitalization", essential: "✓", plus: "✓"),
		.init(feature: "X-Ray & Ultrasound", essential: "✓", plus: "✓"),
		.init(feature: "Lab Test", essential: "✓", plus: "✓"),
		.init(feature: "Medication", essential: "✓", plus: "✓"),
		.init(feature: "Consultation", essential: "—", plus: "✓"),
		.init(feature: "Specialist Consultation", essential: "—", plus: "✓"),
		.init(feature: "MRI & CT Coverage", essential: "—", plus: "—"),
		.init(feature: "Cancer Cash Additional lump sum", essential: "HKD 10,000", plus: "HKD 10,000"),
		.init(feature: "Additional Critical Illness Cash Benefit", essential: "✓", plus: "✓"),
	]

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					// Selection Section
					VStack(alignment: .leading, spacing: 12) {
						Text("Select Plans to Compare")
							.font(.system(.headline, design: .default).weight(.semibold))
							.foregroundStyle(.primary)

						HStack(spacing: 12) {
							planSelectionButton(
								name: "Essential",
								isSelected: selectedPlans.contains("Essential"),
								action: {
									if selectedPlans.contains("Essential") {
										selectedPlans.remove("Essential")
									} else {
										selectedPlans.insert("Essential")
									}
								}
							)

							planSelectionButton(
								name: "Plus",
								isSelected: selectedPlans.contains("Plus"),
								action: {
									if selectedPlans.contains("Plus") {
										selectedPlans.remove("Plus")
									} else {
										selectedPlans.insert("Plus")
									}
								}
							)
						}
					}
					.padding(16)
					.background(Color(.systemGray6))
					.cornerRadius(8)
					.padding(.horizontal, 16)
					.padding(.top, 16)

					// Plan header cards - only show selected
					if !selectedPlans.isEmpty {
						HStack(spacing: 12) {
							if selectedPlans.contains("Essential") {
								planCard(
									name: essentialPlan.name,
									badge: essentialPlan.badge,
									monthlyPrice: essentialPlan.monthlyPrice,
									monthlyPriceSmall: essentialPlan.monthlyPriceSmall,
									annualPrice: essentialPlan.annualPrice,
									annualPriceSmall: essentialPlan.annualPriceSmall,
									isHighlighted: false
								)
							}

							if selectedPlans.contains("Plus") {
								planCard(
									name: plusPlan.name,
									badge: plusPlan.badge,
									monthlyPrice: plusPlan.monthlyPrice,
									monthlyPriceSmall: plusPlan.monthlyPriceSmall,
									annualPrice: plusPlan.annualPrice,
									annualPriceSmall: plusPlan.annualPriceSmall,
									isHighlighted: true
								)
							}
						}
						.padding(16)
					}

					// Features comparison table - filtered based on selection
					if !selectedPlans.isEmpty {
						VStack(spacing: 0) {
							ForEach(features) { feature in
								featureRow(feature)
								Divider()
									.padding(.leading, 16)
							}
						}
						.padding(.top, 8)
					} else {
						VStack(spacing: 12) {
							Image(systemName: "checkmark.circle.dashed")
								.font(.system(.largeTitle))
								.foregroundStyle(.secondary)

							Text("Select at least one plan to compare")
								.font(.system(.body, design: .default))
								.foregroundStyle(.secondary)
						}
						.frame(maxWidth: .infinity, maxHeight: 200, alignment: .center)
						.padding(32)
					}
				}
			}
			.navigationTitle("Compare Plans")
			.navigationBarTitleDisplayMode(.inline)
		}
	}

	private func planSelectionButton(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack {
				Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
					.foregroundStyle(isSelected ? .blue : .secondary)

				Text(name)
					.foregroundStyle(isSelected ? .blue : .primary)
					.font(.system(.body, design: .default).weight(.medium))

				Spacer()
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 10)
			.padding(.horizontal, 12)
			.background(isSelected ? Color.blue.opacity(0.1) : Color.white)
			.cornerRadius(6)
			.overlay(
				RoundedRectangle(cornerRadius: 6)
					.stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 1)
			)
		}
	}

	private func planCard(
		name: String,
		badge: String,
		monthlyPrice: String,
		monthlyPriceSmall: String,
		annualPrice: String,
		annualPriceSmall: String,
		isHighlighted: Bool
	) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Text(name)
					.font(.system(.body, design: .default).weight(.semibold))
					.foregroundStyle(.primary)

				Spacer()
			}

			Text(badge)
				.font(.system(.caption, design: .default))
				.foregroundStyle(.blue)

			VStack(alignment: .leading, spacing: 2) {
				HStack(spacing: 2) {
					Text(monthlyPrice)
						.font(.system(.title3, design: .default).weight(.bold))
						.foregroundStyle(.blue)

					Text(monthlyPriceSmall)
						.font(.system(.caption))
						.foregroundStyle(.secondary)
				}

				Text(annualPrice)
					.font(.system(.caption2))
					.foregroundStyle(.secondary)

				Text(annualPriceSmall)
					.font(.system(.caption2))
					.foregroundStyle(.secondary)
			}

			Spacer()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(isHighlighted ? Color.blue.opacity(0.1) : Color(.systemGray6))
		.cornerRadius(8)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(isHighlighted ? Color.blue : Color.clear, lineWidth: 2)
		)
	}

	private func featureRow(_ feature: FeatureRow) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Text(feature.feature)
				.font(.system(.caption, design: .default))
				.foregroundStyle(.primary)
				.frame(maxWidth: .infinity, alignment: .leading)
				.lineLimit(4)
				.padding(.vertical, 12)
				.padding(.leading, 16)

			VStack(alignment: .center, spacing: 0) {
				featureValue(feature.essential)
			}
			.frame(maxWidth: 80, alignment: .center)
			.padding(.vertical, 12)

			VStack(alignment: .center, spacing: 0) {
				featureValue(feature.plus)
			}
			.frame(maxWidth: 80, alignment: .center)
			.padding(.vertical, 12)
			.padding(.trailing, 16)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private func featureValue(_ value: String) -> some View {
		if value == "✓" {
			return AnyView(
				Image(systemName: "checkmark")
					.font(.system(.body, design: .default).weight(.semibold))
					.foregroundStyle(.green)
			)
		} else if value == "—" {
			return AnyView(
				Text("—")
					.font(.system(.body, design: .default).weight(.semibold))
					.foregroundStyle(.secondary)
			)
		} else {
			return AnyView(
				Text(value)
					.font(.system(.caption, design: .default))
					.foregroundStyle(.primary)
					.multilineTextAlignment(.center)
					.lineLimit(3)
			)
		}
	}
}

struct InsuranceCompareView_Previews: PreviewProvider {
	static var previews: some View {
		InsuranceCompareView()
	}
}

