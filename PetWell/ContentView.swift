//
//  ContentView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .shop
    @State private var isGuardianPresented = false
    @State private var guardianButtonPosition: CGPoint = .zero
    @State private var guardianButtonDragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TabView(selection: $selectedTab) {
                    ProductsView()
                        .tabItem { Label("Shop", systemImage: "bag") }
                        .tag(Tab.shop)

                    ClinicView()
                        .tabItem { Label("Medical", systemImage: "cross.case") }
                        .tag(Tab.medical)

                    InsuranceView()
                        .tabItem { Label("Insurance", systemImage: "shield") }
                        .tag(Tab.insurance)

                    RecordsView()
                        .tabItem { Label("Profile", systemImage: "doc.text") }
                        .tag(Tab.profile)
                }

                // Floating PetWell Guardian button (draggable)
                Button {
                    isGuardianPresented = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 6)
                        .accessibilityLabel("PetWell Guardian")
                }
                .position(x: guardianButtonPosition.x + guardianButtonDragOffset.width,
                          y: guardianButtonPosition.y + guardianButtonDragOffset.height)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guardianButtonDragOffset = value.translation
                        }
                        .onEnded { value in
                            let buttonRadius: CGFloat = 28 // approx half of button diameter
                            let padding: CGFloat = 12

                            var newX = guardianButtonPosition.x + value.translation.width
                            var newY = guardianButtonPosition.y + value.translation.height

                            // Clamp inside the screen
                            newX = min(max(newX, buttonRadius + padding), geo.size.width - buttonRadius - padding)
                            newY = min(max(newY, buttonRadius + padding), geo.size.height - buttonRadius - padding)

                            guardianButtonPosition = CGPoint(x: newX, y: newY)
                            guardianButtonDragOffset = .zero
                        }
                )
                .onAppear {
                    // Set default position (bottom-right) once
                    if guardianButtonPosition == .zero {
                        let buttonRadius: CGFloat = 28
                        let padding: CGFloat = 18
                        guardianButtonPosition = CGPoint(
                            x: geo.size.width - buttonRadius - padding,
                            y: geo.size.height - buttonRadius - padding
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isGuardianPresented) {
            GuardianChatView()
        }
    }
}

private enum Tab: Hashable {
    case shop, medical, insurance, profile
}

// MARK: - Placeholder screens (MVP stubs)

private struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("PetWell")
                    .font(.largeTitle).bold()

                Text("Shop (unused stub)")
                    .font(.title3)

                Text("Next: pet overview + reminders.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Shop")
        }
    }
}




private struct ClinicView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vaccination & Medical (MVP stub)")
                    .font(.title2).bold()

                Text("Next: clinic list + booking flow.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Medical")
        }
    }
}

private struct InsuranceView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Insurance (MVP stub)")
                    .font(.title2).bold()

                Text("Next: plans comparison + recommendations.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Insurance")
        }
    }
}

private struct ProductsView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Products (MVP stub)")
                    .font(.title2).bold()

                Text("Next: health products list + details.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Shop")
        }
    }
}


#Preview {
    ContentView()
}
