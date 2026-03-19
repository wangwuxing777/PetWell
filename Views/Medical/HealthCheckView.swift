import SwiftUI

struct HealthCheckView: View {
    // Mock Data for Health Check Packages
    let packages = [
        HealthCheckPackage(
            id: 1,
            title: "Comprehensive Dog Health Check",
            subtitle: "Includes Blood Test, X-Ray, Physical Exam",
            price: 1280,
            originalPrice: 2500,
            soldCount: 1542,
            rating: 4.9,
            tags: ["Anytime Refund", "No Appointment"],
            imageName: "dog_checkup"
        ),
        HealthCheckPackage(
            id: 2,
            title: "Senior Cat Wellness Plan",
            subtitle: "Kidney Function, Dental Check, Ultrasound",
            price: 880,
            originalPrice: 1600,
            soldCount: 892,
            rating: 4.8,
            tags: ["Senior Care", "Expert Vet"],
            imageName: "cat_checkup"
        ),
        HealthCheckPackage(
            id: 3,
            title: "Basic Puppy Vaccination & Exam",
            subtitle: "Core Vaccines + Deworming + Physical",
            price: 450,
            originalPrice: 800,
            soldCount: 3201,
            rating: 5.0,
            tags: ["Best Seller", "Puppy Essential"],
            imageName: "puppy_checkup"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Banner / Header
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                       .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                       .frame(height: 180)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pet Health Checks")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Professional Care for Your Furry Friends")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(20)
                }
                
                // Filters / Categories (Mock)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(title: "All", isSelected: true)
                        FilterChip(title: "Dogs", isSelected: false)
                        FilterChip(title: "Cats", isSelected: false)
                        FilterChip(title: "Senior Pets", isSelected: false)
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
                
                // Package List
                LazyVStack(spacing: 16) {
                    ForEach(packages) { package in
                        HealthCheckCard(package: package)
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Health Check")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBarWhenPushed()
    }
}

// Model
struct HealthCheckPackage: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let price: Int
    let originalPrice: Int
    let soldCount: Int
    let rating: Double
    let tags: [String]
    let imageName: String
}

// Components
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
    }
}

struct HealthCheckCard: View {
    let package: HealthCheckPackage
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Image Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "stethoscope")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(package.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(package.subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    // Tags
                    HStack(spacing: 4) {
                        ForEach(package.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 2)
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("HK$")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("\(package.price)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Text("HK$\(package.originalPrice)")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        
                        Spacer()
                        
                        Text("Sold \(package.soldCount)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Footer Info
            HStack {
                Label("\(String(format: "%.1f", package.rating)) Rating", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Spacer()
                Text("Valid for 90 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
