import SwiftUI
import UIKit
import PhotosUI

// Helper extension for rounding specific corners
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

struct OwnerProfileEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  let isMandatory: Bool
  let onSaved: (OwnerProfile) -> Void

  @State private var profile: OwnerProfile = OwnerProfileStore.shared.load()
  @State private var pickerItem: PhotosPickerItem?
  @State private var validationMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("Owner Profile") {
          HStack(spacing: 12) {
            if let data = profile.avatarImageData, let ui = UIImage(data: data) {
              Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
              Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            }
            PhotosPicker(selection: $pickerItem, matching: .images) {
              Text("Change Avatar")
            }
          }

          TextField("Owner Name", text: $profile.name)
          TextField("Email", text: $profile.email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
          TextField("Phone", text: $profile.phone)
            .keyboardType(.phonePad)
        }

        if let validationMessage {
          Section {
            Text(validationMessage)
              .foregroundColor(.red)
              .font(.footnote)
          }
        }
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if !isMandatory {
            Button("Cancel") { dismiss() }
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
        }
      }
      .task(id: pickerItem) {
        guard let pickerItem else { return }
        if let data = try? await pickerItem.loadTransferable(type: Data.self) {
          profile.avatarImageData = data
        }
      }
    }
  }

  private func save() {
    let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines)
    let phone = profile.phone.trimmingCharacters(in: .whitespacesAndNewlines)
    if name.isEmpty || email.isEmpty || phone.isEmpty {
      validationMessage = "Please complete name, email, and phone before continuing."
      return
    }
    profile.name = name
    profile.email = email
    profile.phone = phone
    OwnerProfileStore.shared.save(profile)
    onSaved(profile)
    dismiss()
  }
}
