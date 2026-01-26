import SwiftUI

struct ClinicSelectionView: View {
    let vaccine: Vaccine
    @State private var clinics: [Clinic] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    var filteredClinics: [Clinic] {
        if searchText.isEmpty {
            return clinics
        }
        return clinics.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a Clinic")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Choose where you want to book \(vaccine.name)")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search clinics...", text: $searchText)
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if filteredClinics.isEmpty {
                    Text("No clinics found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredClinics) { clinic in
                            NavigationLink(destination: VaccineBookingView(vaccine: vaccine, clinic: clinic)) {
                                ClinicSelectionCard(clinic: clinic)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                self.clinics = try await ClinicService.shared.fetchAllClinics()
                self.isLoading = false
            } catch {
                print("Error fetching clinics: \(error)")
                self.isLoading = false
            }
        }
    }
}

struct ClinicSelectionCard: View {
    let clinic: Clinic
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left color strip
            Rectangle()
                .fill(Color.blue)
                .frame(width: 6)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(clinic.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .offset(y: 1)
                    Text(clinic.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Label(clinic.openingHours, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Select")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
