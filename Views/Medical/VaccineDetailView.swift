import SwiftUI

struct VaccineDetailView: View {
    let vaccine: Vaccine
    
    // Environment to dismiss if needed
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Header
                ZStack(alignment: .bottomLeading) {
                    // Abstract Background
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: geo.size.height + (geo.frame(in: .global).minY > 0 ? geo.frame(in: .global).minY : 0))
                        .offset(y: (geo.frame(in: .global).minY > 0 ? -geo.frame(in: .global).minY : 0))
                    }
                    .frame(height: 280)
                    
                    // Decorative Icon
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .foregroundColor(.white.opacity(0.1))
                        .offset(x: 150, y: -20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(vaccine.petType.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        Text(vaccine.name)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                        
                        // Price tag
                        HStack(spacing: 4) {
                            Text("Est.")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                            Text("$\(vaccine.price)")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60) // Increased padding to prevent overlap
                }
                .frame(height: 320) // Increased Header Height
                
                VStack(alignment: .leading, spacing: 28) {
                    
                    // Highlights Section - Fixed & Full Width
                    HStack(spacing: 8) {
                        Group {
                            if vaccine.isCore {
                                HighlightBadge(icon: "star.fill", title: "Core", color: .orange)
                            } else {
                                HighlightBadge(icon: "star", title: "Non-Core", color: .gray)
                            }
                            
                            if vaccine.isMandatory {
                                HighlightBadge(icon: "exclamationmark.shield.fill", title: "Mandatory", color: .red)
                            }
                            
                            HighlightBadge(icon: "tag.fill", title: "In-Clinic", color: .green)
                        }
                        .frame(maxWidth: .infinity) // Make each badge fill available space
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 35) // Increased top padding to avoid corner clipping
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(vaccine.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Schedule Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Vaccination Schedule")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                        
                        ScheduleRow(
                            title: youngStageTitle,
                            description: vaccine.youngInfo,
                            icon: "hourglass.bottomhalf.fill",
                            color: .blue
                        )
                        
                        Divider().padding(.leading, 70) // Separator
                        
                        ScheduleRow(
                            title: "Adult Stage",
                            description: vaccine.adultInfo,
                            icon: "hourglass.tophalf.fill",
                            color: .purple
                        )
                    }
                    
                    // Button (Scrollable)
                    Button(action: {
                        // Action for booking
                    }) {
                        Text("Book Appointment")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .offset(y: -40) // Move card up to overlap header
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(Color(UIColor.systemGroupedBackground))
        .toolbar(.hidden, for: .tabBar) // Hide Bottom Tab Bar
    }
    
    // Dynamic Title Logic
    private var youngStageTitle: String {
        let type = vaccine.petType.lowercased()
        if type.contains("dog") && type.contains("cat") {
            return "Puppy / Kitten Stage"
        } else if type.contains("cat") {
            return "Kitten Stage"
        } else {
            return "Puppy Stage"
        }
    }
}

// MARK: - Subviews

struct HighlightBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ScheduleRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                // Removed background circle for cleaner alignment look
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
            }
            .padding(.top, 2) // Align icon visually with text cap-height element
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 20) // Match header padding exactly
        // Removed background and cornerRadius to fix indentation "misalignment" feeling
    }
}

struct VaccineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VaccineDetailView(vaccine: Vaccine(
            id: 1,
            name: "Rabies",
            petType: "dog/cat",
            description: "A must-have vaccine that protects your pet from rabies — a deadly virus.",
            youngInfo: "First dose at 12–16 weeks old.",
            adultInfo: "Booster 1 year later.",
            isCore: true,
            isMandatory: true,
            price: 280
        ))
    }
}
