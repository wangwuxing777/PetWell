import SwiftUI

struct VaccineView: View {
    @State private var searchText = ""
    @State private var vaccines: [Vaccine] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var dogVaccines: [Vaccine] {
        vaccines.filter { $0.petType.contains("dog") || $0.petType.contains("dog/cat") }
    }
    
    var catVaccines: [Vaccine] {
        vaccines.filter { $0.petType.contains("cat") || $0.petType.contains("dog/cat") }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading vaccines...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error loading data")
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
                    VStack(spacing: 0) {
                        // High-End Header
                        VStack(alignment: .leading, spacing: 16) {
                                Text("Pet Health Center")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("Search vaccines, services...", text: $searchText)
                                }
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }
                            .background(Color(UIColor.systemBackground))
                            .zIndex(1)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 24) {
                            
                            // "Service Near Me" with Modern Cards
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Services")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        NavigationLink(destination: EmergencyClinicsView()) {
                                            ServiceCard(title: "24h Medical", subtitle: "Support", imageName: "cross.case.fill", color: .red)

                                        }
                                        NavigationLink(destination: HealthCheckView()) {
                                            ServiceCard(title: "Health Check", subtitle: "Regular", imageName: "stethoscope", color: .blue)
                                        }
                                        ServiceCard(title: "Deworming", subtitle: "Treatment", imageName: "pills.fill", color: .green)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Dog Vaccination Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Dog Vaccination")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(dogVaccines) { vaccine in
                                            VaccineCard(vaccine: vaccine)
                                                .frame(width: 200)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Cat Vaccination Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cat Vaccination")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(catVaccines) { vaccine in
                                            VaccineCard(vaccine: vaccine)
                                                .frame(width: 200)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground)) // Subtle light gray background
            .task {
                loadData()
            }
        }
    }

    private func loadData() {
        isLoading = true
        Task {
            do {
                self.vaccines = try await VaccineService.shared.fetchVaccines()
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ServiceCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: imageName)
                    .foregroundColor(color)
                    .font(.system(size: 24))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 140, height: 130)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct VaccineCard: View {
    let vaccine: Vaccine
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Clean Image Area
            ZStack(alignment: .topTrailing) {
                // Background Frame
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                
                if let uiImage = UIImage(named: vaccine.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill() // Fill the area, cropping if needed
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped() // Ensure it doesn't bleed out
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 140)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.3))
                        )
                }
                
                // Minimal Badge
                if vaccine.isCore {
                    Text("CORE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(8)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 2. Structured Content
            VStack(alignment: .leading, spacing: 10) {
                Text(vaccine.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(alignment: .center) {
                    Text("$\(vaccine.price)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    NavigationLink(destination: VaccineDetailView(vaccine: vaccine)) {
                        Text("Book")
                           .font(.system(size: 12, weight: .bold))
                           .foregroundColor(.blue)
                           .padding(.horizontal, 14)
                           .padding(.vertical, 6)
                           .background(Color.blue.opacity(0.1))
                           .cornerRadius(20)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity) // Ensure content fills the width strictly
        }
        .background(Color(UIColor.systemBackground)) // Add background to the whole card container
        .frame(width: 200, height: 220) // Specify fixed width again to ensure container is rigid
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
