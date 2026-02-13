import SwiftUI
import UIKit

struct VetMapContainerView: View {
  @StateObject private var viewModel = VetMapViewModel()
  @Environment(\.presentationMode) var presentationMode
  @State private var showFilterSheet = false

  var body: some View {
    ZStack(alignment: .top) {
      // Map Layer
      MapViewWrapper(viewModel: viewModel)
        .edgesIgnoringSafeArea(.all)

      // UI Layer
      VStack(spacing: 0) {
        // Top Bar & Search
        HStack(spacing: 12) {
          // Back Button
          Button(action: {
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "chevron.left")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.black)
              .frame(width: 44, height: 44)
              .background(Color.white)
              .clipShape(Circle())
              .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
          }

          // Search Bar
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.gray)

            TextField("Search vets...", text: $viewModel.searchText)
              .foregroundColor(.primary)

            if !viewModel.searchText.isEmpty {
              Button(action: {
                viewModel.searchText = ""
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.gray)
              }
            }
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 16)
          .background(Color.white)
          .cornerRadius(25)
          .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)

          // Filter Button
          Button(action: {
            showFilterSheet = true
          }) {
            Image(systemName: "slider.horizontal.3")
              .font(.system(size: 24, weight: .semibold))
              .foregroundColor(.black)
              .padding(10)
              .background(Color.white)
              .clipShape(Circle())
              .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
          }
        }
        .padding(.horizontal)
        .padding(.top, 8)

        Spacer()

        // Loading indicator
        if viewModel.isLoading {
          ProgressView("Searching clinics...")
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 4)
        }

        // Error message
        if let error = viewModel.errorMessage {
          Text(error)
            .font(.caption)
            .foregroundColor(.red)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
        }

        // Bottom Sheet for Selected Clinic
        if let clinic = viewModel.selectedClinic {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(clinic.name)
                  .font(.title3)
                  .fontWeight(.bold)

                Text(clinic.businessStatus)
                  .font(.subheadline)
                  .foregroundColor(.gray)
              }
              Spacer()

              Button(action: {
                viewModel.selectedClinic = nil
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.gray)
                  .font(.title2)
              }
            }

            Divider()

            HStack(spacing: 16) {
              Label(
                clinic.isOpen ? "Open Now" : "Closed",
                systemImage: "clock"
              )
              .font(.caption)
              .foregroundColor(clinic.isOpen ? .green : .red)
            }

            Text(clinic.address)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)

            Button(action: {
              let coordinate = "\(clinic.lat),\(clinic.lng)"
              if let url = URL(string: "http://maps.apple.com/?daddr=\(coordinate)") {
                UIApplication.shared.open(url)
              }
            }) {
              Text("Get Directions")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
          }
          .padding()
          .background(Color.white)
          .cornerRadius(20, corners: [.topLeft, .topRight])
          .shadow(radius: 10)
          .transition(.move(edge: .bottom))
          .animation(.spring(), value: viewModel.selectedClinic)
        }
      }
    }
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .blur(radius: showFilterSheet ? 5 : 0)
    .sheet(isPresented: $showFilterSheet) {
      FilterSheetView(viewModel: viewModel)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
}

struct FilterSheetView: View {
  @ObservedObject var viewModel: VetMapViewModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      HStack(spacing: 0) {
        // Left Column: Regions
        List(VetMapViewModel.Region.allCases, id: \.self) { region in
          HStack {
            Text(region.rawValue)
              .font(.headline)
              .foregroundColor(viewModel.selectedRegion == region ? .primary : .secondary)
            Spacer()
            if viewModel.selectedRegion == region {
              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            withAnimation {
              viewModel.selectRegion(region)
            }
          }
          .listRowBackground(
            viewModel.selectedRegion == region
              ? Color.white : Color(UIColor.secondarySystemBackground)
          )
        }
        .listStyle(.plain)
        .frame(width: 140)
        .background(Color(UIColor.secondarySystemBackground))

        // Right Column: Districts
        List {
          if let districts = viewModel.districtsByRegion[viewModel.selectedRegion] {
            Button(action: {
              dismiss()
            }) {
              Text("All of \(viewModel.selectedRegion.rawValue)")
                .fontWeight(.medium)
                .foregroundColor(.primary)
            }

            ForEach(districts, id: \.slug) { district in
              Button(action: {
                viewModel.selectDistrict(district.slug)
                dismiss()
              }) {
                HStack {
                  Text(district.display)
                    .foregroundColor(
                      viewModel.selectedDistrict == district.slug ? .blue : .primary
                    )
                  Spacer()
                  if viewModel.selectedDistrict == district.slug {
                    Image(systemName: "checkmark")
                      .foregroundColor(.blue)
                  }
                }
              }
            }
          }
        }
        .listStyle(.plain)
      }
      .navigationTitle("Filter")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .foregroundColor(.blue)
        }
      }
    }
  }
}
