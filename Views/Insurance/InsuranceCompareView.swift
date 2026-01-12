//
//  InsuranceCompareView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI
import SwiftData
import UIKit

// A UIScrollView-backed container that reports its contentOffset to SwiftUI
struct OffsettableScrollView<Content: View>: UIViewRepresentable {
	@Binding var contentOffset: CGPoint
	let content: Content

	init(contentOffset: Binding<CGPoint>, @ViewBuilder content: () -> Content) {
		self._contentOffset = contentOffset
		self.content = content()
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func makeUIView(context: Context) -> UIScrollView {
		let scrollView = UIScrollView()
		scrollView.alwaysBounceVertical = true
		scrollView.alwaysBounceHorizontal = true
		scrollView.showsVerticalScrollIndicator = true
		scrollView.showsHorizontalScrollIndicator = true

		let hosting = UIHostingController(rootView: content)
		context.coordinator.hostingController = hosting

		hosting.view.translatesAutoresizingMaskIntoConstraints = false
		hosting.view.backgroundColor = UIColor.clear

		scrollView.addSubview(hosting.view)

		// Pin hosting view to scrollView content layout guide
		NSLayoutConstraint.activate([
			hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
			hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
			hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
			hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

			// Allow content to determine size; but do not force width to scrollView's frame
			hosting.view.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor)
		])

		scrollView.addObserver(context.coordinator, forKeyPath: "contentOffset", options: .new, context: nil)
		context.coordinator.scrollView = scrollView

		return scrollView
	}

	func updateUIView(_ uiView: UIScrollView, context: Context) {
		// Update the hosted SwiftUI content when body changes
		context.coordinator.hostingController?.rootView = content
	}

	static func dismantleUIView(_ uiView: UIScrollView, coordinator: Coordinator) {
		if let c = coordinator.scrollView {
			c.removeObserver(coordinator, forKeyPath: "contentOffset")
		}
		coordinator.hostingController = nil
	}

	class Coordinator: NSObject {
		var parent: OffsettableScrollView
		weak var scrollView: UIScrollView?
		var hostingController: UIHostingController<Content>?

		init(_ parent: OffsettableScrollView) {
			self.parent = parent
		}

		override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
			guard keyPath == "contentOffset", let scroll = object as? UIScrollView else { return }
			DispatchQueue.main.async {
				self.parent.contentOffset = scroll.contentOffset
			}
		}
	}
}

// Simple compare view with a sticky header row and sticky first column.
struct InsuranceCompareView: View {
	// sample model: attribute titles and plan values
	struct RowData: Identifiable {
		let id = UUID()
		let attribute: String
		let values: [String]
	}

	private let plans = ["Plan A", "Plan B", "Plan C", "Plan D"]
	private let rows: [RowData] = [
		.init(attribute: "Monthly", values: ["$25","$32","$28","$20"]),
		.init(attribute: "Deductible", values: ["$200","$150","$100","$300"]),
		.init(attribute: "Coverage", values: ["80%","90%","85%","75%"]),
		.init(attribute: "Accident", values: ["Yes","Yes","No","Yes"]),
		.init(attribute: "Illness", values: ["Yes","Partial","Yes","No"]),
		.init(attribute: "Age Limit", values: ["Up to 10","Up to 12","Up to 14","No limit"]),
		.init(attribute: "Waiting Period", values: ["14 days","30 days","7 days","14 days"]),
		.init(attribute: "Annual Max", values: ["$5,000","$10,000","$8,000","$3,000"]),
	]

	@State private var contentOffset: CGPoint = .zero

	// layout constants
	private let firstColumnWidth: CGFloat = 140
	private let columnWidth: CGFloat = 120
	private let rowHeight: CGFloat = 48

	var body: some View {
		NavigationStack {
			ZStack(alignment: .topLeading) {
				// The full grid inside a scrollable container that reports offsets
				OffsettableScrollView(contentOffset: $contentOffset) {
					VStack(spacing: 0) {
						// Header Row (including top-left empty cell)
						HStack(spacing: 0) {
							headerCell(text: "")
								.frame(width: firstColumnWidth, height: rowHeight)

							ForEach(plans, id: \\ .self) { plan in
								headerCell(text: plan)
									.frame(width: columnWidth, height: rowHeight)
							}
						}

						// Data rows
						ForEach(rows) { row in
							HStack(spacing: 0) {
								firstColumnCell(text: row.attribute)
									.frame(width: firstColumnWidth, height: rowHeight)

								ForEach(row.values.indices, id: \\ .self) { idx in
									dataCell(text: row.values[idx])
										.frame(width: columnWidth, height: rowHeight)
								}
							}
						}
					}
				}

				// Sticky header overlay (moves horizontally with content)
				VStack(spacing: 0) {
					HStack(spacing: 0) {
						headerCell(text: "")
							.frame(width: firstColumnWidth, height: rowHeight)

						HStack(spacing: 0) {
							ForEach(plans, id: \\ .self) { plan in
								headerCell(text: plan)
									.frame(width: columnWidth, height: rowHeight)
							}
						}
						.offset(x: -contentOffset.x)
					}
					Spacer()
				}
				.allowsHitTesting(false)
				.background(Color.clear)

				// Sticky first column overlay (moves vertically with content)
				VStack(spacing: 0) {
					firstColumnCell(text: "Plans")
						.frame(width: firstColumnWidth, height: rowHeight)

					VStack(spacing: 0) {
						ForEach(rows) { row in
							firstColumnCell(text: row.attribute)
								.frame(width: firstColumnWidth, height: rowHeight)
						}
					}
					.offset(y: -contentOffset.y)
				}
				.allowsHitTesting(false)
				.background(Color.clear)
			}
			.navigationTitle("Compare Plans")
			.padding(.top, 0)
		}
	}

	// MARK: - Cell Views
	private func headerCell(text: String) -> some View {
		ZStack {
			Rectangle().fill(Color(.systemGray6))
			Text(text)
				.font(.system(.subheadline, weight: .semibold))
				.foregroundStyle(.primary)
				.multilineTextAlignment(.center)
				.padding(6)
		}
		.border(Color(.separator), width: 0.5)
	}

	private func firstColumnCell(text: String) -> some View {
		ZStack(alignment: .leading) {
			Rectangle().fill(Color(.systemBackground))
			Text(text)
				.font(.system(.subheadline))
				.foregroundStyle(.primary)
				.padding(.leading, 12)
		}
		.border(Color(.separator), width: 0.5)
	}

	private func dataCell(text: String) -> some View {
		ZStack {
			Rectangle().fill(Color(.systemBackground))
			Text(text)
				.font(.system(.subheadline))
				.foregroundStyle(.primary)
				.multilineTextAlignment(.center)
				.padding(6)
		}
		.border(Color(.separator), width: 0.5)
	}
}

struct InsuranceCompareView_Previews: PreviewProvider {
	static var previews: some View {
		InsuranceCompareView()
	}
}

