import SwiftUI
import SwiftData

// MARK: - PetSelectorSheet
// Shown when user triggers "For Me" and there are multiple pets.
// Single pet → launches ForYouProgressView directly (no selector needed).

struct PetSelectorSheet: View {
    let onSelect: (PetModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PetModel.name) private var pets: [PetModel]

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    emptyState
                } else {
                    petList
                }
            }
            .navigationTitle("Select Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("PetSelectorCancelButton")
                }
            }
        }
        .accessibilityIdentifier("PetSelectorSheet")
    }

    // MARK: - Pet List

    private var petList: some View {
        List(pets) { pet in
            Button(action: {
                onSelect(pet)   // 先记录选择
                dismiss()       // 再关闭 sheet（onDismiss 回调完成后才弹出 fullScreenCover）
            }) {
                HStack(spacing: 14) {
                    // Avatar
                    Group {
                        if let data = pet.avatarImageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: pet.species.lowercased().contains("cat") ? "cat.fill" : "dog.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(LinearGradient(
                                    colors: [.blue.opacity(0.65), .purple.opacity(0.65)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                    }
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(pet.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(pet.breed) · \(Calendar.current.component(.year, from: .now) - pet.birthYear) yr(s)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray3))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("PetSelectorRow_\(pet.name)")
        }
        .accessibilityIdentifier("PetSelectorList")
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(.systemGray3))
            Text("No pets added yet")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Add a pet in the Profile tab to get personalised insurance recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
