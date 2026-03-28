//
//  SharePetProfileView.swift
//  PetWell
//
//  Created on 2026/01/23.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct SharePetProfileView: View {
    let petId: String
    let petName: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager

    @State private var selectedFriends: Set<String> = []
    @State private var accessStartDate: Date = Date()
    @State private var accessEndDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var permission: SharePermission = .private
    @State private var allowDownload: Bool = true

    @State private var shareLink: String?
    @State private var qrCodeImage: UIImage?
    @State private var isLoading = false
    @State private var showLink = false
    @State private var showCopiedToast = false

    // Mock friends data - replace with real data later
    let mockFriends = [
        Friend(id: "1", name: "Emma Wilson", avatar: "person.circle.fill"),
        Friend(id: "2", name: "James Chen", avatar: "person.circle.fill"),
        Friend(id: "3", name: "Sophie Taylor", avatar: "person.circle.fill"),
        Friend(id: "4", name: "Oliver Brown", avatar: "person.circle.fill"),
    ]

    enum SharePermission: String, CaseIterable {
        case `private` = "private"
        case `public` = "public"

        func displayName(isChinese: Bool) -> String {
            switch self {
            case .private: return isChinese ? "私人" : "Private"
            case .public: return isChinese ? "公開" : "Public"
            }
        }
    }

    var body: some View {
        NavigationStack {
            if showLink, let link = shareLink {
                // Share Link Generated View
                shareLinkView(link: link)
            } else {
                // Share Configuration View
                configurationView
            }
        }
    }

    // MARK: - Configuration View
    private var configurationView: some View {
        Form {
            // MARK: - Selected Friends Section
            Section {
                if selectedFriends.isEmpty {
                    Text(languageManager.isChinese ? "未選擇好友" : "No friends selected")
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
                Text(languageManager.isChinese ? "分享給" : "Share With")
            } footer: {
                Text(languageManager.isChinese ? "選擇可以看到 \(petName) 檔案的好友" : "Select friends who can view \(petName)'s profile")
            }

            // MARK: - Friend Selection
            Section(languageManager.isChinese ? "選擇好友" : "Select Friends") {
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

            // MARK: - Permission
            Section(languageManager.isChinese ? "權限" : "Permission") {
                Picker(languageManager.isChinese ? "訪問權限" : "Access Permission", selection: $permission) {
                    ForEach(SharePermission.allCases, id: \.self) { perm in
                        Text(perm.displayName(isChinese: languageManager.isChinese)).tag(perm)
                    }
                }

                Toggle(languageManager.isChinese ? "允許下載圖片" : "Allow Image Download", isOn: $allowDownload)
            }

            // MARK: - Access Time Range
            Section {
                DatePicker(languageManager.isChinese ? "開始日期" : "Start Date", selection: $accessStartDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker(languageManager.isChinese ? "結束日期" : "End Date", selection: $accessEndDate, in: accessStartDate..., displayedComponents: [.date, .hourAndMinute])
            } header: {
                Text(languageManager.isChinese ? "訪問時間" : "Access Time Range")
            } footer: {
                Text(languageManager.isChinese ? "好友只能在設定的時間範圍內查看檔案" : "Friends can only view the profile during this time period")
            }

            // MARK: - Quick Duration Options
            Section(languageManager.isChinese ? "快速設定" : "Quick Duration") {
                HStack(spacing: 12) {
                    durationButton(title: languageManager.isChinese ? "1天" : "1 Day", days: 1)
                    durationButton(title: languageManager.isChinese ? "7天" : "7 Days", days: 7)
                    durationButton(title: languageManager.isChinese ? "30天" : "30 Days", days: 30)
                    durationButton(title: languageManager.isChinese ? "90天" : "90 Days", days: 90)
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
                        if isLoading {
                            ProgressView()
                        } else {
                            Label(languageManager.isChinese ? "建立分享連結" : "Create Share Link", systemImage: "link")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(selectedFriends.isEmpty || isLoading)
            }
        }
        .navigationTitle(languageManager.isChinese ? "分享 \(petName)" : "Share \(petName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(languageManager.isChinese ? "取消" : "Cancel") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Share Link View
    private func shareLinkView(link: String) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text(languageManager.isChinese ? "分享連結已建立" : "Share Link Created")
                    .font(.title2.weight(.bold))

                // QR Code
                VStack(spacing: 12) {
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 180, height: 180)
                            .overlay(
                                ProgressView()
                            )
                    }

                    Text(languageManager.isChinese ? "掃描二維碼" : "Scan QR Code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                // Share Link
                VStack(spacing: 8) {
                    Text(languageManager.isChinese ? "分享連結" : "Share Link")
                        .font(.headline)

                    HStack {
                        Text(link)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .lineLimit(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)

                        Button {
                            UIPasteboard.general.string = link
                            showCopiedToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedToast = false
                            }
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // Action Buttons
                HStack(spacing: 16) {
                    // Copy Link
                    Button {
                        UIPasteboard.general.string = link
                        showCopiedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopiedToast = false
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.title2)
                            Text(languageManager.isChinese ? "複製連結" : "Copy Link")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Share Sheet
                    ShareLink(item: URL(string: link)!) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text(languageManager.isChinese ? "分享" : "Share")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                // New Share Button
                Button {
                    showLink = false
                    shareLink = nil
                } label: {
                    Text(languageManager.isChinese ? "建立新連結" : "Create New Link")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle(languageManager.isChinese ? "分享連結" : "Share Link")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(languageManager.isChinese ? "完成" : "Done") {
                    dismiss()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                Text(languageManager.isChinese ? "已複製！" : "Copied!")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helper Views
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

    // MARK: - Actions
    private func shareProfile() {
        isLoading = true

        Task {
            // Call API to create share link
            // POST /api/pets/{id}/share
            // Request: { "permission": "private", "expires_at": "2024-12-31T23:59:59Z", "allow_download": true }

            // For demo, create mock share link
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let mockToken = UUID().uuidString.prefix(8)
            let shareUrl = "https://petwell.app/share/\(mockToken)"

            await MainActor.run {
                shareLink = shareUrl
                qrCodeImage = generateQRCode(from: shareUrl)
                isLoading = false
                showLink = true
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code
        let scale = 10.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Friend Model
struct Friend: Identifiable {
    let id: String
    let name: String
    let avatar: String
}

// MARK: - Share Service
class ShareService {
    // TODO: Replace with actual API call
    // POST /api/pets/{id}/share

    static func createShareLink(
        petId: String,
        permission: String,
        expiresAt: Date?,
        allowDownload: Bool
    ) async throws -> ShareLinkResponse {

        let baseURL = "https://pawrd-backend.zeabur.app"
        guard let url = URL(string: "\(baseURL)/pets/\(petId)/share") else {
            throw ShareError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "permission": permission,
            "allow_download": allowDownload
        ]

        if let expiresAt = expiresAt {
            let formatter = ISO8601DateFormatter()
            body["expires_at"] = formatter.string(from: expiresAt)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw ShareError.serverError
        }

        return try JSONDecoder().decode(ShareLinkResponse.self, from: data)
    }
}

enum ShareError: Error {
    case invalidURL
    case serverError
}

struct ShareLinkResponse: Decodable {
    let success: Bool
    let data: ShareLinkData?
}

struct ShareLinkData: Decodable {
    let shareToken: String
    let shareUrl: String
    let qrCodeUrl: String?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case shareToken = "share_token"
        case shareUrl = "share_url"
        case qrCodeUrl = "qr_code_url"
        case expiresAt = "expires_at"
    }
}

#Preview {
    SharePetProfileView(petId: "123", petName: "Buddy")
        .environmentObject(LanguageManager())
}
