//
//  ActivityTrackingView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI
import Charts

struct ActivityTrackingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedPet: ActivityPet?
    @State private var activities: [PetActivity] = []
    @State private var isLoading = false
    @State private var selectedDate = Date()

    // Mock pets for activity tracking
    let pets: [ActivityPet] = [
        ActivityPet(id: "1", name: "Max", species: "dog", avatar: "dog.fill"),
        ActivityPet(id: "2", name: "Bella", species: "cat", avatar: "cat.fill")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pet Selector
                petSelector

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if activities.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Today's Summary
                            todaySummaryCard

                            // Activity Chart
                            activityChart

                            // Activity Records
                            activityRecords
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(languageManager.isChinese ? "活動追蹤" : "Activity Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Add new activity
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadActivities()
            }
        }
    }

    // MARK: - Pet Selector
    private var petSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pets) { pet in
                    Button {
                        selectedPet = pet
                        loadActivities()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: pet.avatar)
                                .font(.title3)
                            Text(pet.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedPet?.id == pet.id ? Color.blue : Color.secondary.opacity(0.1))
                        .foregroundColor(selectedPet?.id == pet.id ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Today's Summary
    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(languageManager.isChinese ? "今日摘要" : "Today's Summary")
                    .font(.headline)
                Spacer()
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
                // Steps
                ActivityStatCard(
                    icon: "figure.walk",
                    value: "\(todayStats.steps)",
                    unit: languageManager.isChinese ? "步" : "steps",
                    color: .blue,
                    progress: Double(todayStats.steps) / 10000
                )

                // Sleep
                ActivityStatCard(
                    icon: "moon.zzz.fill",
                    value: "\(todayStats.sleepHours)",
                    unit: languageManager.isChinese ? "小時" : "hrs",
                    color: .purple,
                    progress: Double(todayStats.sleepHours) / 14
                )

                // Meals
                ActivityStatCard(
                    icon: "fork.knife",
                    value: "\(todayStats.meals)",
                    unit: languageManager.isChinese ? "餐" : "meals",
                    color: .orange,
                    progress: Double(todayStats.meals) / 3
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Activity Chart
    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.isChinese ? "每週活動" : "Weekly Activity")
                .font(.headline)

            Chart(weeklyData) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Steps", item.steps)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Activity Records
    private var activityRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.isChinese ? "活動記錄" : "Activity Records")
                .font(.headline)

            ForEach(activities) { activity in
                ActivityRecordRow(activity: activity, isChinese: languageManager.isChinese)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(languageManager.isChinese ? "暫無活動數據" : "No Activity Data")
                .font(.headline)
            Text(languageManager.isChinese ? "開始記錄寵物的活動吧" : "Start tracking your pet's activities")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                // Add first activity
            } label: {
                Label(languageManager.isChinese ? "添加活動" : "Add Activity", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            Spacer()
        }
    }

    // MARK: - Computed Properties
    private var todayStats: TodayStats {
        let steps = activities.filter { $0.type == .walk }.reduce(0) { $0 + $1.value }
        let sleep = activities.filter { $0.type == .sleep }.first?.value ?? 0
        let meals = activities.filter { $0.type == .meal }.count
        return TodayStats(steps: steps, sleepHours: sleep, meals: meals)
    }

    private var weeklyData: [WeeklyActivity] {
        [
            WeeklyActivity(day: "Mon", steps: 8500),
            WeeklyActivity(day: "Tue", steps: 6200),
            WeeklyActivity(day: "Wed", steps: 9800),
            WeeklyActivity(day: "Thu", steps: 7500),
            WeeklyActivity(day: "Fri", steps: 11200),
            WeeklyActivity(day: "Sat", steps: 5600),
            WeeklyActivity(day: "Sun", steps: 4300)
        ]
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    // MARK: - Actions
    private func loadActivities() {
        isLoading = true
        selectedPet = selectedPet ?? pets.first

        // Mock data for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            activities = PetActivity.mockData
            isLoading = false
        }
    }
}

// MARK: - Activity Stat Card
private struct ActivityStatCard: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Record Row
private struct ActivityRecordRow: View {
    let activity: PetActivity
    let isChinese: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: activity.type.icon)
                    .foregroundColor(activity.type.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline.weight(.medium))
                Text(activity.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Value
            if activity.type == .meal {
                Text(activity.notes ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(activity.value) \(activity.type == .walk ? (isChinese ? "步" : "steps") : (isChinese ? "小時" : "hrs"))")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(activity.type.color)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models
struct ActivityPet: Identifiable {
    let id: String
    let name: String
    let species: String
    let avatar: String
}

struct PetActivity: Identifiable {
    let id: String
    let petId: String
    let type: ActivityType
    let value: Int
    let notes: String?
    let timestamp: Date

    var title: String {
        switch type {
        case .walk: return type.displayName
        case .sleep: return type.displayName
        case .meal: return type.displayName
        case .medication: return type.displayName
        case .vetVisit: return type.displayName
        case .other: return type.displayName
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    enum ActivityType: String, CaseIterable {
        case walk
        case sleep
        case meal
        case medication
        case vetVisit
        case other

        var icon: String {
            switch self {
            case .walk: return "figure.walk"
            case .sleep: return "moon.zzz.fill"
            case .meal: return "fork.knife"
            case .medication: return "pills.fill"
            case .vetVisit: return "cross.case.fill"
            case .other: return "ellipsis.circle"
            }
        }

        var color: Color {
            switch self {
            case .walk: return .blue
            case .sleep: return .purple
            case .meal: return .orange
            case .medication: return .red
            case .vetVisit: return .green
            case .other: return .gray
            }
        }

        var displayName: String {
            switch self {
            case .walk: return "Walk"
            case .sleep: return "Sleep"
            case .meal: return "Meal"
            case .medication: return "Medication"
            case .vetVisit: return "Vet Visit"
            case .other: return "Other"
            }
        }
    }

    static var mockData: [PetActivity] {
        [
            PetActivity(id: "1", petId: "1", type: .walk, value: 5000, notes: nil, timestamp: Date()),
            PetActivity(id: "2", petId: "1", type: .meal, value: 1, notes: "Breakfast - Dry food", timestamp: Date().addingTimeInterval(-3600 * 6)),
            PetActivity(id: "3", petId: "1", type: .sleep, value: 8, notes: nil, timestamp: Date().addingTimeInterval(-3600 * 3)),
            PetActivity(id: "4", petId: "1", type: .walk, value: 3500, notes: "Evening walk", timestamp: Date().addingTimeInterval(-3600 * 2)),
            PetActivity(id: "5", petId: "1", type: .meal, value: 1, notes: "Dinner - Wet food", timestamp: Date().addingTimeInterval(-3600)),
            PetActivity(id: "6", petId: "1", type: .medication, value: 1, notes: "Heartworm prevention", timestamp: Date().addingTimeInterval(-86400))
        ]
    }
}

struct WeeklyActivity: Identifiable {
    let id = UUID()
    let day: String
    let steps: Int
}

struct TodayStats {
    let steps: Int
    let sleepHours: Int
    let meals: Int
}

// MARK: - Activity Service (Placeholder)
class ActivityService {
    // TODO: Connect to backend API
    // GET /api/pets/{id}/activities

    static func fetchActivities(petId: String, date: Date? = nil) async -> [PetActivity] {
        // Placeholder
        try? await Task.sleep(nanoseconds: 500_000_000)
        return PetActivity.mockData
    }
}

#Preview {
    ActivityTrackingView()
        .environmentObject(LanguageManager())
}
