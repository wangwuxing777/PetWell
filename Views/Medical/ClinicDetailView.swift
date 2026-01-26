import SwiftUI

struct ClinicDetailView: View {
    let clinic: Clinic
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 250)
                    
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title and Badge
                    VStack(alignment: .leading, spacing: 8) {
                        if clinic.emergency24h.uppercased() == "TRUE" {
                            Text("24H EMERGENCY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                        
                        Text(clinic.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                     Divider()

                    // Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(icon: "mappin.circle.fill", text: clinic.address, color: .blue)
                        InfoRow(icon: "clock.fill", text: clinic.openingHours, color: .orange)
                        if let rating = clinic.rating, !rating.isEmpty {
                            InfoRow(icon: "star.fill", text: "Rating: \(rating)", color: .yellow)
                        }
                    }
                    
                    Divider()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if let phone = clinic.phoneEmergency, !phone.isEmpty {
                            ActionButton(title: "Call Emergency", icon: "phone.fill", color: .red) {
                                call(phone)
                            }
                        }
                        
                        if let phone = clinic.phoneRegular, !phone.isEmpty {
                            // Only show regular phone if it's different or emergency is not set, 
                            // but usually listing both is fine if they exist.
                            ActionButton(title: "Call Regular", icon: "phone", color: .blue) {
                                call(phone)
                            }
                        }
                        
                        if let urlString = clinic.applemapUrl, let url = URL(string: urlString) {
                            Link(destination: url) {
                                ActionButtonLabel(title: "Open in Maps", icon: "map.fill", color: .green)
                            }
                        }
                        
                        if let urlString = clinic.websiteUrl, let url = URL(string: urlString) {
                             Link(destination: url) {
                                ActionButtonLabel(title: "Visit Website", icon: "globe", color: .gray)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func call(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
             ActionButtonLabel(title: title, icon: icon, color: color)
        }
    }
}

struct ActionButtonLabel: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}
