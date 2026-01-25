//
//  SharePetProfileView.swift
//  PetWell
//
//  Created on 2026/01/23.
//

import SwiftUI

struct SharePetProfileView: View {
    let petName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFriends: Set<String> = []
    @State private var accessStartDate: Date = Date()
    @State private var accessEndDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60) // Default 7 days
    @State private var showSuccessAlert = false
    
    // Mock friends data - replace with real data later
    let mockFriends = [
        Friend(id: "1", name: "Emma Wilson", avatar: "person.circle.fill"),
        Friend(id: "2", name: "James Chen", avatar: "person.circle.fill"),
        Friend(id: "3", name: "Sophie Taylor", avatar: "person.circle.fill"),
        Friend(id: "4", name: "Oliver Brown", avatar: "person.circle.fill"),
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Selected Friends Section
                Section {
                    if selectedFriends.isEmpty {
                        Text("No friends selected")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(mockFriends.filter { selectedFriends.contains($0.id) }) { friend in
                            HStack {
                                Image(systemName: friend.avatar)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text(friend.name)
                                Spacer()
                                Button {
                                    selectedFriends.remove(friend.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Share With")
                } footer: {
                    Text("Select friends who can view \(petName)'s profile")
                }
                
                // MARK: - Friend Selection
                Section("Select Friends") {
                    ForEach(mockFriends) { friend in
                        Button {
                            if selectedFriends.contains(friend.id) {
                                selectedFriends.remove(friend.id)
                            } else {
                                selectedFriends.insert(friend.id)
                            }
                        } label: {
                            HStack {
                                Image(systemName: friend.avatar)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text(friend.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedFriends.contains(friend.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Access Time Range
                Section {
                    DatePicker("Start Date", selection: $accessStartDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date", selection: $accessEndDate, in: accessStartDate..., displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Access Time Range")
                } footer: {
                    Text("Friends can only view the profile during this time period")
                }
                
                // MARK: - Quick Duration Options
                Section("Quick Duration") {
                    HStack(spacing: 12) {
                        durationButton(title: "1 Day", days: 1)
                        durationButton(title: "7 Days", days: 7)
                        durationButton(title: "30 Days", days: 30)
                        durationButton(title: "90 Days", days: 90)
                    }
                    .listRowBackground(Color.clear)
                }
                
                // MARK: - Share Button
                Section {
                    Button {
                        shareProfile()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedFriends.isEmpty)
                }
            }
            .navigationTitle("Share \(petName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Profile Shared!", isPresented: $showSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("\(petName)'s profile has been shared with \(selectedFriends.count) friend(s).")
            }
        }
    }
    
    private func durationButton(title: String, days: Int) -> some View {
        Button {
            accessStartDate = Date()
            accessEndDate = Date().addingTimeInterval(Double(days) * 24 * 60 * 60)
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func shareProfile() {
        // TODO: Implement actual sharing logic with backend
        showSuccessAlert = true
    }
}

// MARK: - Friend Model
struct Friend: Identifiable {
    let id: String
    let name: String
    let avatar: String
}

#Preview {
    SharePetProfileView(petName: "Buddy")
}
