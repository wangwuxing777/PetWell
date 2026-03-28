//
//  BookingRecordView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI
import SwiftData

struct BookingRecordView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Query(sort: \PetModel.name) private var pets: [PetModel]

    @State private var bookings: [BookingRecord] = []
    @State private var isLoading = false
    @State private var selectedPet: PetModel?
    @State private var selectedFilter: BookingFilter = .all

    enum BookingFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }

    var filteredBookings: [BookingRecord] {
        let petFiltered = selectedPet != nil
            ? bookings.filter { $0.petName == selectedPet!.name }
            : bookings

        switch selectedFilter {
        case .all:
            return petFiltered
        case .upcoming:
            return petFiltered.filter { $0.status == .confirmed || $0.status == .pending }
        case .completed:
            return petFiltered.filter { $0.status == .completed }
        case .cancelled:
            return petFiltered.filter { $0.status == .cancelled }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pet Selection (Level 1 Menu)
            petSelectorView

            // Status Filter (Level 2 Menu) - only show after pet selected
            if selectedPet != nil {
                filterTabsView
            }

            // Content
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if selectedPet == nil {
                selectPetPromptView
            } else if filteredBookings.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredBookings) { booking in
                            BookingCard(booking: booking)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(languageManager.isChinese ? "預約記錄" : "Booking Record")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBarWhenPushed()
        .onAppear {
            loadBookings()
        }
    }

    // MARK: - Pet Selector View
    private var petSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(pets) { pet in
                    PetSelectorCard(
                        pet: pet,
                        isSelected: selectedPet?.id == pet.id,
                        onTap: { selectedPet = pet }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Filter Tabs View
    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BookingFilter.allCases, id: \.self) { filter in
                    BookingFilterChip(
                        title: filterTitle(filter),
                        isSelected: selectedFilter == filter,
                        onTap: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .top
        )
    }

    // MARK: - Select Pet Prompt
    private var selectPetPromptView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "pawprint.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))

            Text(languageManager.isChinese ? "請先選擇一隻寵物" : "Please Select a Pet")
                .font(.headline)

            Text(languageManager.isChinese ? "從上方選擇一隻寵物以查看其預約記錄" : "Choose a pet from above to view their booking records")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
    }

    private func filterTitle(_ filter: BookingFilter) -> String {
        switch filter {
        case .all: return languageManager.isChinese ? "全部" : "All"
        case .upcoming: return languageManager.isChinese ? "即將到來" : "Upcoming"
        case .completed: return languageManager.isChinese ? "已完成" : "Completed"
        case .cancelled: return languageManager.isChinese ? "已取消" : "Cancelled"
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(languageManager.isChinese ? "暫無預約記錄" : "No Booking Records")
                .font(.headline)
            Text(languageManager.isChinese ? "預約疫苗或就診後將顯示在這裡" : "Your appointments will appear here after booking")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func loadBookings() {
        isLoading = true
        // Mock data for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            bookings = BookingRecord.mockData
            isLoading = false
        }
        // TODO: Replace with actual API call
        // Task {
        //     isLoading = true
        //     bookings = await BookingService.fetchBookings()
        //     isLoading = false
        // }
    }
}

// MARK: - Filter Chip
private struct BookingFilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Booking Card
private struct BookingCard: View {
    let booking: BookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Service Icon
                ZStack {
                    Circle()
                        .fill(serviceColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: serviceIcon)
                        .foregroundColor(serviceColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.serviceType)
                        .font(.headline)
                    Text(booking.clinicName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: booking.status)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(booking.formattedDate)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label {
                        Text(booking.formattedTime)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("HKD \(booking.price)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }

            if booking.notes.isEmpty == false {
                Text(booking.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var serviceIcon: String {
        switch booking.serviceType.lowercased() {
        case "vaccination": return "syringe.fill"
        case "checkup": return "stethoscope"
        case "consultation": return "person.badge.plus"
        default: return "cross.case.fill"
        }
    }

    private var serviceColor: Color {
        switch booking.serviceType.lowercased() {
        case "vaccination": return .green
        case "checkup": return .blue
        case "consultation": return .orange
        default: return .purple
        }
    }
}

// MARK: - Status Badge
private struct StatusBadge: View {
    let status: BookingStatus

    var body: some View {
        Text(statusText)
            .font(.caption.weight(.medium))
            .foregroundColor(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(12)
    }

    private var statusText: String {
        switch status {
        case .confirmed: return "Confirmed"
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    private var statusColor: Color {
        switch status {
        case .confirmed: return .green
        case .pending: return .orange
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

// MARK: - Booking Model
struct BookingRecord: Codable, Identifiable {
    let id: UUID
    let clinicId: Int
    let clinicName: String
    let clinicAddress: String
    let serviceType: String
    let petName: String
    let scheduledDate: Date
    let scheduledTime: String
    let price: Int
    let status: BookingStatus
    let notes: String
    let createdAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledDate)
    }

    var formattedTime: String {
        scheduledTime
    }

    static var mockData: [BookingRecord] {
        [
            BookingRecord(
                id: UUID(),
                clinicId: 1,
                clinicName: "Happy Paws Veterinary",
                clinicAddress: "123 Pet Street, Hong Kong",
                serviceType: "Vaccination",
                petName: "Max",
                scheduledDate: Date().addingTimeInterval(86400 * 3),
                scheduledTime: "10:00 AM",
                price: 350,
                status: .confirmed,
                notes: "Annual rabies vaccination",
                createdAt: Date().addingTimeInterval(-86400)
            ),
            BookingRecord(
                id: UUID(),
                clinicId: 2,
                clinicName: "City Pet Clinic",
                clinicAddress: "456 Central Road",
                serviceType: "Checkup",
                petName: "Bella",
                scheduledDate: Date().addingTimeInterval(86400 * 7),
                scheduledTime: "2:30 PM",
                price: 280,
                status: .pending,
                notes: "Annual health checkup",
                createdAt: Date()
            ),
            BookingRecord(
                id: UUID(),
                clinicId: 1,
                clinicName: "Happy Paws Veterinary",
                clinicAddress: "123 Pet Street, Hong Kong",
                serviceType: "Consultation",
                petName: "Max",
                scheduledDate: Date().addingTimeInterval(-86400 * 14),
                scheduledTime: "11:00 AM",
                price: 450,
                status: .completed,
                notes: "Skin problem consultation",
                createdAt: Date().addingTimeInterval(-86400 * 20)
            )
        ]
    }
}

enum BookingStatus: String, Codable {
    case confirmed
    case pending
    case completed
    case cancelled
}

// MARK: - Booking Service (Placeholder)
class BookingService {
    // TODO: Replace with actual API call
    // static func fetchBookings() async -> [BookingRecord] {
    //     guard let url = URL(string: "https://pawrd-backend.zeabur.app/api/bookings") else {
    //         return []
    //     }
    //     var request = URLRequest(url: url)
    //     request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    //
    //     let (data, _) = try await URLSession.shared.data(for: request)
    //     return try JSONDecoder().decode([BookingRecord].self, from: data)
    // }

    static func fetchBookings() async -> [BookingRecord] {
        // Placeholder - return mock data
        try? await Task.sleep(nanoseconds: 500_000_000)
        return BookingRecord.mockData
    }
}

// MARK: - Pet Selector Card
private struct PetSelectorCard: View {
    let pet: PetModel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray3))
                        .frame(width: 56, height: 56)

                    if let data = pet.avatarImageData,
                       let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: pet.species.lowercased().contains("cat") ? "cat.fill" : "dog.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

                // Name
                Text(pet.name)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .frame(width: 80)
    }
}

#Preview {
    NavigationStack {
        BookingRecordView()
            .environmentObject(LanguageManager())
    }
}
