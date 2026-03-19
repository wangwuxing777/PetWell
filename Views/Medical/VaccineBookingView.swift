import SwiftData
import SwiftUI

struct VaccineBookingView: View {
  let vaccine: Vaccine
  let clinic: Clinic
  @Environment(\.dismiss) var dismiss
  @Query(sort: \PetModel.name) private var storedPets: [PetModel]

  // Form State
  @State private var selectedPetName: String = ""
  @State private var selectedDate: Date = Date()
  @State private var selectedTimeSlot: String?
  @State private var additionalNotes: String = ""
  @State private var showResultAlert = false
  @State private var resultAlertTitle = ""
  @State private var resultAlertMessage = ""
  @State private var dismissOnAlertDone = false
  @State private var isSubmitting = false
  @State private var showOwnerProfileEditor = false
  @State private var step: BookingStep = .booking
  @State private var unavailableSlots: Set<String> = []

  let timeSlots = [
    "11:00", "11:30", "12:00", "12:30", "13:00",
    "14:00", "14:30", "15:00", "15:30", "16:00",
  ]

  private var dateOptions: [Date] {
    let calendar = Calendar.current
    return (0..<7).compactMap {
      calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: Date()))
    }
  }

  private var petOptions: [String] {
    storedPets
      .map(\.name)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  private var canProceed: Bool {
    selectedTimeSlot != nil && !selectedPetName.isEmpty && !isSubmitting
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          ProgressStepperView(activeStep: step == .booking ? 2 : 3)
            .padding(.top, 12)

          if step == .booking {
            Text("Date")
              .font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 10) {
                ForEach(dateOptions, id: \.self) { date in
                  DatePillView(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    onTap: { selectedDate = date }
                  )
                }
              }
            }

            Text("Time")
              .font(.title2.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 10)], spacing: 10) {
              ForEach(timeSlots, id: \.self) { slot in
                TimePillView(
                  title: slot,
                  isSelected: selectedTimeSlot == slot,
                  isDisabled: unavailableSlots.contains(slot),
                  onTap: {
                    guard !unavailableSlots.contains(slot) else { return }
                    selectedTimeSlot = slot
                  }
                )
              }
            }

            Text("For")
              .font(.title3.bold())
            if petOptions.isEmpty {
              Text("No pet profile found. Please add a pet in Profile first.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                  ForEach(petOptions, id: \.self) { petName in
                    Button {
                      selectedPetName = petName
                    } label: {
                      Text("For \(petName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selectedPetName == petName ? .white : .accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                          selectedPetName == petName
                            ? Color.accentColor : Color.accentColor.opacity(0.12)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                  }
                }
              }
            }
          } else {
            let owner = OwnerProfileStore.shared.load()
            Text("Appointment")
              .font(.caption)
              .foregroundColor(.secondary)
            ContactInfoRow(label: "", value: vaccine.name, icon: "stethoscope")

            Text("Contact Information")
              .font(.title2.bold())
            ContactInfoRow(
              label: "Name", value: owner.name.isEmpty ? "—" : owner.name, icon: "person")
            ContactInfoRow(
              label: "Telephone", value: owner.phone.isEmpty ? "—" : owner.phone, icon: "phone")

            Text("Note")
              .font(.title3.bold())
            TextEditor(text: $additionalNotes)
              .frame(height: 130)
              .padding(8)
              .background(Color(UIColor.secondarySystemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
              Text("Service")
                .font(.caption)
                .foregroundColor(.secondary)
              Text(vaccine.name)
                .font(.headline)
              Text("\(selectedPetName) · \(selectedTimeSlot ?? "--:--")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
        }
        .padding(20)
        .padding(.bottom, 96)
      }

      VStack(spacing: 0) {
        Divider()
        HStack {
          Button(action: {
            if step == .booking {
              guard canProceed else { return }
              step = .confirmation
              return
            }
            Task { await confirmAppointment() }
          }) {
            HStack(spacing: 8) {
              if isSubmitting {
                ProgressView()
                  .progressViewStyle(.circular)
                  .tint(.white)
              }
              Text(step == .booking ? "Done" : (isSubmitting ? "Submitting..." : "Done"))
                .fontWeight(.bold)
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canProceed ? Color.accentColor : Color.gray.opacity(0.6))
            .clipShape(Capsule())
          }
          .disabled(!canProceed)
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(step == .booking ? "Booking" : "Confirmation")
          .font(.title2.weight(.bold))
      }
    }
    .alert(resultAlertTitle, isPresented: $showResultAlert) {
      Button("Done") {
        if dismissOnAlertDone {
          dismiss()
        }
      }
    } message: {
      Text(resultAlertMessage)
    }
    .sheet(isPresented: $showOwnerProfileEditor) {
      OwnerProfileEditorSheet(isMandatory: true) { _ in }
    }
    .task {
      if selectedPetName.isEmpty, let first = petOptions.first {
        selectedPetName = first
      }
      await refreshUnavailableSlots()
    }
    .task(id: selectedDate) {
      await refreshUnavailableSlots()
    }
    .hideTabBarWhenPushed()
  }

  private func confirmAppointment() async {
    guard let selectedTimeSlot else { return }
    guard OwnerProfileStore.shared.hasRequiredContact() else {
      showOwnerProfileEditor = true
      return
    }
    isSubmitting = true
    defer { isSubmitting = false }

    let owner = OwnerProfileStore.shared.load()
    let petName = selectedPetName
    let ownerName = owner.name.isEmpty ? "Owner" : owner.name
    let ownerEmail = owner.email.isEmpty ? "owner@petwell.test" : owner.email
    let ownerPhone = owner.phone.isEmpty ? "+85200000000" : owner.phone
    let localTime = MerchantClinicSyncService.composeScheduledAt(
      date: selectedDate, slot: selectedTimeSlot)
    let chiefComplaint = [
      "OwnerName: \(ownerName)",
      "OwnerEmail: \(ownerEmail)",
      "OwnerPhone: \(ownerPhone)",
      "Service: \(vaccine.name)",
      "Pet: \(petName)",
      additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? nil : "Notes: \(additionalNotes)",
    ]
    .compactMap { $0 }
    .joined(separator: " | ")

    let payload = MerchantCreateAppointmentRequest(
      pet_id: petName,
      doctor_id: "testclinics_frontdesk",
      scheduled_at: localTime,
      status: "booked",
      chief_complaint: chiefComplaint
    )

    do {
      _ = try await MerchantClinicSyncService.shared.createTestClinicAppointment(payload)
      unavailableSlots.insert(selectedTimeSlot)
      resultAlertTitle = "Booking Confirmed!"
      resultAlertMessage =
        "Appointment sent to testclinics. Merchant clinic panel can now refresh to see this booking."
      dismissOnAlertDone = true
      showResultAlert = true
    } catch {
      resultAlertTitle = "Booking Failed"
      resultAlertMessage = error.localizedDescription
      dismissOnAlertDone = false
      showResultAlert = true
    }
  }

  private func refreshUnavailableSlots() async {
    do {
      unavailableSlots = try await MerchantClinicSyncService.shared.bookedSlots(on: selectedDate)
      if let selected = selectedTimeSlot, unavailableSlots.contains(selected) {
        selectedTimeSlot = nil
      }
    } catch {
      // Keep current UI responsive for testing even if backend fetch fails.
    }
  }
}

// Subcomponents

private enum BookingStep {
  case booking
  case confirmation
}

private struct ProgressStepperView: View {
  let activeStep: Int
  private let titles = ["Your\nChoice", "Make a\nBooking", "Confirmation"]
  private let circleSize: CGFloat = 24

  var body: some View {
    VStack(spacing: 10) {
      GeometryReader { geometry in
        let totalWidth = geometry.size.width
        let columnWidth = totalWidth / 3
        let startX = columnWidth / 2
        let endX = totalWidth - (columnWidth / 2)
        let progress = CGFloat(max(min(activeStep - 1, 2), 0)) / 2
        let progressX = startX + (endX - startX) * progress

        ZStack {
          Path { path in
            path.move(to: CGPoint(x: startX, y: circleSize / 2))
            path.addLine(to: CGPoint(x: endX, y: circleSize / 2))
          }
          .stroke(Color.gray.opacity(0.2), lineWidth: 2.5)

          Path { path in
            path.move(to: CGPoint(x: startX, y: circleSize / 2))
            path.addLine(to: CGPoint(x: progressX, y: circleSize / 2))
          }
          .stroke(Color.accentColor, lineWidth: 2.5)

          HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
              stepCircle(stepNo: index + 1)
                .frame(maxWidth: .infinity)
            }
          }
        }
      }
      .frame(height: circleSize)

      HStack(spacing: 0) {
        ForEach(0..<3, id: \.self) { index in
          Text(titles[index])
            .font(.footnote.weight(.semibold))
            .foregroundColor(index + 1 <= activeStep ? .primary : .gray.opacity(0.45))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
      }
    }
  }

  @ViewBuilder
  private func stepCircle(stepNo: Int) -> some View {
    Circle()
      .fill(stepNo <= activeStep ? Color.accentColor : Color(UIColor.systemGray5))
      .frame(width: circleSize, height: circleSize)
      .overlay {
        if stepNo == 1 {
          Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
        } else {
          Text("\(stepNo)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(stepNo <= activeStep ? .white : .white.opacity(0.92))
        }
      }
  }
}

private struct DatePillView: View {
  let date: Date
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 4) {
        Text(date.formatted(.dateTime.weekday(.abbreviated)))
          .font(.caption2)
        Text(date.formatted(.dateTime.day()))
          .font(.title3.weight(.bold))
      }
      .foregroundColor(isSelected ? .white : .secondary)
      .frame(width: 54, height: 84)
      .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}

private struct TimePillView: View {
  let title: String
  let isSelected: Bool
  let isDisabled: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundColor(isDisabled ? .gray : (isSelected ? Color.accentColor : .primary))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isDisabled ? Color.gray.opacity(0.18) : Color.white)
        .overlay(
          RoundedRectangle(cornerRadius: 18)
            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
        )
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
  }
}

private struct ContactInfoRow: View {
  let label: String
  let value: String
  let icon: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !label.isEmpty {
        Text(label)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      HStack(spacing: 10) {
        Image(systemName: icon)
          .foregroundColor(.secondary)
        Text(value)
          .font(.title3.weight(.semibold))
      }
      Divider()
    }
  }
}

private struct MerchantCreateAppointmentRequest: Encodable {
  let pet_id: String
  let doctor_id: String
  let scheduled_at: String
  let status: String
  let chief_complaint: String
}

private struct MerchantLoginRequest: Encodable {
  let method = "email"
  let email = "testclinics@petwell.com"
  let password = "Clinic123456"
}

private struct MerchantLoginResponse: Decodable {
  let session_id: String
}

private struct MerchantCreateAppointmentResponse: Decodable {
  let id: String
}

private enum MerchantClinicSyncError: LocalizedError {
  case invalidResponse
  case unauthorized
  case server(String)

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Merchant backend response is invalid."
    case .unauthorized:
      return "Merchant session expired. Please retry."
    case .server(let message):
      return message
    }
  }
}

private actor MerchantClinicSyncService {
  static let shared = MerchantClinicSyncService()

  private let baseURL = URL(string: "http://localhost:8090")!
  private let sessionStorageKey = "petwell_testclinics_session_id"

  private struct MerchantAppointmentRow: Decodable {
    let scheduled_at: String
  }

  func createTestClinicAppointment(_ payload: MerchantCreateAppointmentRequest) async throws
    -> String
  {
    let sessionID = try await ensureSessionID()
    return try await postAppointment(payload, sessionID: sessionID)
  }

  func bookedSlots(on date: Date) async throws -> Set<String> {
    let sessionID = try await ensureSessionID()
    var request = URLRequest(url: baseURL.appendingPathComponent("api/merchant/appointments"))
    request.httpMethod = "GET"
    request.setValue(sessionID, forHTTPHeaderField: "X-Session-ID")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw MerchantClinicSyncError.invalidResponse
    }
    if http.statusCode == 401 {
      UserDefaults.standard.removeObject(forKey: sessionStorageKey)
      return try await bookedSlots(on: date)
    }
    guard (200...299).contains(http.statusCode) else {
      return []
    }
    let rows = (try? JSONDecoder().decode([MerchantAppointmentRow].self, from: data)) ?? []
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "HH:mm"
    var out: Set<String> = []
    for row in rows {
      guard let dt = ISO8601DateFormatter().date(from: row.scheduled_at) else { continue }
      if calendar.isDate(dt, inSameDayAs: date) {
        out.insert(formatter.string(from: dt))
      }
    }
    return out
  }

  private func ensureSessionID() async throws -> String {
    if let cachedSession = UserDefaults.standard.string(forKey: sessionStorageKey),
      !cachedSession.isEmpty
    {
      return cachedSession
    }
    let sessionID = try await loginForTestClinic()
    UserDefaults.standard.set(sessionID, forKey: sessionStorageKey)
    return sessionID
  }

  private func loginForTestClinic() async throws -> String {
    var request = URLRequest(url: baseURL.appendingPathComponent("api/merchant/auth/login"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(MerchantLoginRequest())

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw MerchantClinicSyncError.invalidResponse
    }
    guard (200...299).contains(http.statusCode) else {
      let message =
        Self.extractErrorMessage(from: data) ?? "Merchant login failed (\(http.statusCode))."
      throw MerchantClinicSyncError.server(message)
    }

    let decoded = try JSONDecoder().decode(MerchantLoginResponse.self, from: data)
    return decoded.session_id
  }

  private func postAppointment(_ payload: MerchantCreateAppointmentRequest, sessionID: String)
    async throws -> String
  {
    var request = URLRequest(url: baseURL.appendingPathComponent("api/merchant/appointments"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(sessionID, forHTTPHeaderField: "X-Session-ID")
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw MerchantClinicSyncError.invalidResponse
    }
    if http.statusCode == 401 {
      throw MerchantClinicSyncError.unauthorized
    }
    guard (200...299).contains(http.statusCode) else {
      let message =
        Self.extractErrorMessage(from: data) ?? "Create appointment failed (\(http.statusCode))."
      throw MerchantClinicSyncError.server(message)
    }

    let created = try JSONDecoder().decode(MerchantCreateAppointmentResponse.self, from: data)
    return created.id
  }

  private static func extractErrorMessage(from data: Data) -> String? {
    guard
      let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let error = raw["error"] as? [String: Any],
      let message = error["message"] as? String
    else {
      return nil
    }
    return message
  }

  static func composeScheduledAt(date: Date, slot: String) -> String {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let parts = slot.split(separator: ":")
    comps.hour = Int(parts.first ?? "0") ?? 0
    comps.minute = Int(parts.last ?? "0") ?? 0
    comps.second = 0
    let merged = Calendar.current.date(from: comps) ?? date
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: merged)
  }
}
