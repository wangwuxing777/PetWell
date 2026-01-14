//
//  InsuranceCompareView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI

struct InsuranceCompareView: View {
	@State private var companies: [InsuranceCompany] = []
	@State private var selectedCompany: InsuranceCompany?
	@State private var productsForCompany: [InsuranceProduct] = []
	@State private var selectedProduct: InsuranceProduct?
	@State private var plansForProduct: [InsurancePlan] = []
	@State private var selectedPlanIds: Set<Int> = []
	@State private var isLoading = false

	private let service = InsuranceService.shared

	struct CoverageRowData: Identifiable {
		let id = UUID()
		let label: String
		let value: String

		static func fromProfile(_ profile: ProductCoverageProfile) -> [CoverageRowData] {
			return [
				.init(label: "Annual Coverage Limit", value: profile.annualLimitAmount.map { "HKD \($0)" } ?? "—"),
				.init(label: "Reimbursement Rate", value: profile.reimbursementPercent.map { "\($0)%" } ?? "—"),
				.init(label: "Surgery Covered", value: (profile.typicalSurgeryCovered == 1) ? "✓" : "—"),
				.init(label: "Chronic Illness Support", value: (profile.chronicIllnessSupported == 1) ? "✓" : "—"),
				.init(label: "Sub-limits", value: profile.hasSubLimits == 1 ? "Yes" : "No"),
				.init(label: "No Sub-limit Tag", value: (profile.noSubLimitMarketingTag == 1) ? "✓" : "—"),
				.init(label: "Inpatient Surgery Included", value: (profile.inpatientSurgeryIncluded == 1) ? "✓" : "—"),
				.init(label: "Online Claims", value: (profile.onlineClaimSupported == 1) ? "✓" : "—"),
				.init(label: "Claim Speed", value: profile.claimProcessSpeedNote ?? "—"),
				.init(label: "Brand Reputation", value: profile.brandReputationSummary ?? "—"),
			]
		}
	}

	var body: some View {
		NavigationStack {
			if isLoading {
				VStack {
					ProgressView()
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				}
			} else {
				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						// Step 1: Company Selection
						VStack(alignment: .leading, spacing: 12) {
							Text("Step 1: Select a Company")
								.font(.system(.headline, design: .default).weight(.semibold))
								.foregroundStyle(.primary)

							Picker("Company", selection: $selectedCompany) {
								Text("Choose a company...").tag(nil as InsuranceCompany?)
								ForEach(companies) { company in
									Text(company.displayName).tag(company as InsuranceCompany?)
								}
							}
							.onChange(of: selectedCompany) { _, newCompany in
								if let company = newCompany {
									selectedProduct = nil
									selectedPlanIds.removeAll()
									productsForCompany = service.getProductsByCompany(companyId: company.id)
								}
							}
						}
						.padding(16)
						.background(Color(.systemGray6))
						.cornerRadius(8)
						.padding(.horizontal, 16)
						.padding(.top, 16)

						// Step 2: Product Selection
						if !productsForCompany.isEmpty {
							VStack(alignment: .leading, spacing: 12) {
								Text("Step 2: Select a Product")
									.font(.system(.headline, design: .default).weight(.semibold))
									.foregroundStyle(.primary)

								Picker("Product", selection: $selectedProduct) {
									Text("Choose a product...").tag(nil as InsuranceProduct?)
									ForEach(productsForCompany) { product in
										Text(product.displayName).tag(product as InsuranceProduct?)
									}
								}
								.onChange(of: selectedProduct) { _, newProduct in
									if let product = newProduct {
										selectedPlanIds.removeAll()
										plansForProduct = service.getPlansByProduct(productId: product.id)
									}
								}
							}
							.padding(16)
							.background(Color(.systemGray6))
							.cornerRadius(8)
							.padding(.horizontal, 16)
						}

						// Step 3: Plan Selection
						if let product = selectedProduct, !plansForProduct.isEmpty {
							VStack(alignment: .leading, spacing: 12) {
								Text("Step 3: Select Plans to Compare")
									.font(.system(.headline, design: .default).weight(.semibold))
									.foregroundStyle(.primary)

								VStack(spacing: 10) {
									ForEach(plansForProduct) { plan in
										planSelectionButton(
											plan: plan,
											isSelected: selectedPlanIds.contains(plan.id),
											action: {
												if selectedPlanIds.contains(plan.id) {
													selectedPlanIds.remove(plan.id)
												} else {
													selectedPlanIds.insert(plan.id)
												}
											}
										)
									}
								}
							}
							.padding(16)
							.background(Color(.systemGray6))
							.cornerRadius(8)
							.padding(.horizontal, 16)
						}

						// Plan Details Display
						if let product = selectedProduct, !selectedPlanIds.isEmpty {
							VStack(alignment: .leading, spacing: 12) {
								Text("Plan Details")
									.font(.system(.headline, design: .default).weight(.semibold))
									.foregroundStyle(.primary)
									.padding(.horizontal, 16)

								// Show coverage profile
								if let coverage = service.getCoverageProfile(productId: product.id) {
									VStack(spacing: 0) {
										ForEach(CoverageRowData.fromProfile(coverage)) { row in
											coverageRow(row)
											Divider()
												.padding(.leading, 16)
										}
									}
									.padding(.top, 8)
								}

								// Show selected plans
								HStack(spacing: 12) {
									ForEach(plansForProduct.filter { selectedPlanIds.contains($0.id) }) { plan in
										planCard(plan: plan)
									}
								}
								.padding(.horizontal, 16)
								.padding(.bottom, 8)
							}
							.padding(.vertical, 16)
							.background(Color(.systemGray6))
							.cornerRadius(8)
							.padding(.horizontal, 16)
						} else if selectedProduct != nil {
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
			}
			.navigationTitle("Compare Plans")
			.navigationBarTitleDisplayMode(.inline)
			.onAppear {
				loadData()
			}
		}
	}

	private func loadData() {
		isLoading = true
		companies = service.getAllCompanies()
		isLoading = false
	}

	private func planSelectionButton(plan: InsurancePlan, isSelected: Bool, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack(spacing: 12) {
				Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
					.foregroundStyle(isSelected ? .blue : .secondary)

				VStack(alignment: .leading, spacing: 2) {
					Text(plan.name)
						.font(.system(.body, design: .default).weight(.medium))
						.foregroundStyle(isSelected ? .blue : .primary)

					HStack(spacing: 8) {
						if let premium = plan.typicalMonthlyPremium {
							Text("HKD \(premium)/mo")
								.font(.system(.caption, design: .default))
								.foregroundStyle(.secondary)
						}
						if let limit = plan.annualLimitAmount {
							Text("Limit: HKD \(limit)")
								.font(.system(.caption, design: .default))
								.foregroundStyle(.secondary)
						}
					}
				}

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

	private func planCard(plan: InsurancePlan) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(plan.name)
				.font(.system(.body, design: .default).weight(.semibold))
				.foregroundStyle(.primary)

			if let premium = plan.typicalMonthlyPremium {
				VStack(alignment: .leading, spacing: 2) {
					HStack(spacing: 2) {
						Text("HKD \(premium)")
							.font(.system(.title3, design: .default).weight(.bold))
							.foregroundStyle(.blue)

						Text("/mo")
							.font(.system(.caption))
							.foregroundStyle(.secondary)
					}

					if let limit = plan.annualLimitAmount {
						Text("Annual: HKD \(limit)")
							.font(.system(.caption2))
							.foregroundStyle(.secondary)
					}
				}
			}

			Spacer()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(Color.blue.opacity(0.1))
		.cornerRadius(8)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.blue, lineWidth: 1)
		)
	}

	private func coverageRow(_ row: CoverageRowData) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Text(row.label)
				.font(.system(.caption, design: .default))
				.foregroundStyle(.primary)
				.frame(maxWidth: .infinity, alignment: .leading)
				.lineLimit(3)
				.padding(.vertical, 12)
				.padding(.leading, 16)

			Text(row.value)
				.font(.system(.caption, design: .default))
				.foregroundStyle(.secondary)
				.lineLimit(3)
				.padding(.vertical, 12)
				.padding(.trailing, 16)
				.frame(maxWidth: 150, alignment: .trailing)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

struct InsuranceCompareView_Previews: PreviewProvider {
	static var previews: some View {
		InsuranceCompareView()
	}
}

