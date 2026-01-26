import SwiftUI

struct EmergencyClinicsView: View {
    @State private var clinics: [Clinic] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading clinics...")
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading clinics")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("Retry") {
                        loadData()
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(clinics) { clinic in
                            NavigationLink(destination: ClinicDetailView(clinic: clinic)) {
                                ClinicCard(clinic: clinic)
                            }
                            .buttonStyle(PlainButtonStyle()) // Remove default link styling
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .navigationTitle("24h Emergency Clinics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        Task {
            do {
                self.clinics = try await ClinicService.shared.fetchEmergencyClinics()
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}

struct ClinicCard: View {
    let clinic: Clinic
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. Photo Placeholder (Left)
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray.opacity(0.3))
                
                // Status Badge
                VStack {
                    HStack {
                        Text("24H")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .cornerRadius(4)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: 110)
            
            // 2. Content (Right)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clinic.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .offset(y: 1)
                        Text(clinic.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Moved actions to Detail View
                Text("View Details >")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue.opacity(0.8))
            }
            .padding(12)
        }
        .frame(height: 140) // Fixed height for compact look
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}