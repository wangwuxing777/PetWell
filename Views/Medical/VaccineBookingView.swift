import SwiftUI

struct VaccineBookingView: View {
    let vaccine: Vaccine
    let clinic: Clinic
    @Environment(\.dismiss) var dismiss
    
    // Form State
    @State private var selectedPetId: Int = 1 // Default to first pet
    @State private var selectedDate: Date = Date()
    @State private var selectedTimeSlot: String?
    @State private var additionalNotes: String = ""
    @State private var showConfirmation = false
        
    // Mock Data
    let pets = [
        (id: 1, name: "Max", type: "Dog", image: "dog_avatar"),
        (id: 2, name: "Bella", type: "Cat", image: "cat_avatar")
    ]
    
    let timeSlots = [
        "09:00", "09:30", "10:00", "10:30", "11:00",
        "14:00", "14:30", "15:00", "15:30", "16:00"
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. Service Summary Card
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Image(systemName: "syringe.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vaccine.name)
                                .font(.headline)
                            Text("Vaccination Service")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("$\(vaccine.price)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // 1.5 Selected Clinic
                    VStack(alignment: .leading, spacing: 12) {
                         Text("Selected Clinic")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(clinic.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Text(clinic.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            if let placeId = clinic.googlePlaceId, !placeId.isEmpty {
                                Button(action: {
                                    let q = clinic.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Clinic"
                                    let urlString = "https://www.google.com/maps/search/?api=1&query=\(q)&query_place_id=\(placeId)"
                                    if let url = URL(string: urlString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Image(systemName: "location.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                            } else if let lat = clinic.latitude, let lng = clinic.longitude {
                                Button(action: {
                                    let q = clinic.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                    let urlString = "https://www.google.com/maps/search/?api=1&query=\(q)&center=\(lat),\(lng)"
                                    if let url = URL(string: urlString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Image(systemName: "location.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                            } else if let mapUrlString = clinic.applemapUrl, !mapUrlString.isEmpty, let url = URL(string: mapUrlString) {
                                Link(destination: url) {
                                    Image(systemName: "location.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    Divider()
                    
                    // 2. Select Pet
                    VStack(alignment: .leading, spacing: 12) {
                        Text("For Whom?")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Add New Pet Button
                                Button(action: {}) {
                                    VStack {
                                        ZStack {
                                            Circle()
                                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                .foregroundColor(.gray)
                                                .frame(width: 60, height: 60)
                                            Image(systemName: "plus")
                                                .foregroundColor(.gray)
                                        }
                                        Text("Add")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // Existing Pets
                                ForEach(pets, id: \.id) { pet in
                                    PetSelectionCell(
                                        name: pet.name,
                                        type: pet.type,
                                        isSelected: selectedPetId == pet.id,
                                        onTap: { selectedPetId = pet.id }
                                    )
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 3. Date & Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When?")
                            .font(.headline)
                        
                        DatePicker("Select Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(.horizontal, -16) // visually expand to edges
                            .tint(.blue)
                        
                        Text("Available Slots")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                            ForEach(timeSlots, id: \.self) { slot in
                                TimeSlotCell(
                                    time: slot,
                                    isSelected: selectedTimeSlot == slot,
                                    onTap: { selectedTimeSlot = slot }
                                )
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 4. Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Notes")
                            .font(.headline)
                        
                        TextEditor(text: $additionalNotes)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    // Spacer for bottom bar
                    Spacer().frame(height: 100)
                }
                .padding(20)
            }
            
            // Bottom Action Bar
            VStack(spacing: 0) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(vaccine.price)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Confirm Appointment")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(selectedTimeSlot != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(selectedTimeSlot == nil)
                }
                .padding(20)
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Booking Confirmed!", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("We'll see you and your pet on \(selectedDate.formatted(date: .abbreviated, time: .omitted)) at \(selectedTimeSlot ?? "").")
        }
    }
}

// Subcomponents

struct PetSelectionCell: View {
    let name: String
    let type: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    // Icon placeholder
                    Image(systemName: type == "Dog" ? "pawprint.fill" : "hare.fill") // Simplified icon logic
                        .foregroundColor(isSelected ? .white : .gray)
                        .font(.title3)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 64, height: 64)
                    }
                }
                
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
    }
}

struct TimeSlotCell: View {
    let time: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(time)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .blue : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
    }
}
