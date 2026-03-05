import Combine
import Foundation
import UIKit

struct User: Codable, Identifiable {
  let id: String
  let name: String
  let role: String
}

struct BlogPostModel: Codable, Identifiable {
  let id: String
  let authorName: String
  let authorAvatar: String
  let title: String
  let content: String?
  let imageColor: String
  let likes: Int
  let timestamp: String?
  let imageUrls: [String]?

  enum CodingKeys: String, CodingKey {
    case id, authorName, authorAvatar, title, content, imageColor, likes, timestamp, imageUrls
  }
}

@MainActor
class BlogService: ObservableObject {
  static let shared = BlogService()

  @Published var currentUser: User?
  @Published var posts: [BlogPostModel] = []

  private let baseURL = "http://localhost:8000"

  func registerUser(name: String, role: String = "developer") async {
    let id = UUID().uuidString
    let user = User(id: id, name: name, role: role)

    guard let url = URL(string: "\(baseURL)/register") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      request.httpBody = try JSONEncoder().encode(user)
      let (data, _) = try await URLSession.shared.data(for: request)
      let registeredUser = try JSONDecoder().decode(User.self, from: data)
      self.currentUser = registeredUser
      print("Registered user: \(registeredUser.name)")
    } catch {
      print("Registration failed: \(error)")
    }
  }

  func fetchPosts() async {
    guard let url = URL(string: "\(baseURL)/posts") else { return }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let fetchedPosts = try JSONDecoder().decode([BlogPostModel].self, from: data)
      self.posts = fetchedPosts
    } catch {
      print("Failed to fetch posts: \(error)")
    }
  }

  func createPost(title: String, content: String, images: [UIImage] = []) async {
    guard let user = currentUser else { return }

    // Upload images first and get URLs
    var imageUrls: [String] = []
    for image in images {
      if let url = await uploadImage(image) {
        imageUrls.append(url)
      }
    }

    guard let apiURL = URL(string: "\(baseURL)/posts") else { return }

    let newPost = BlogPostModel(
      id: "",  // Server assigns ID
      authorName: user.name,
      authorAvatar: "person.circle.fill",
      title: title,
      content: content,
      imageColor: "blue",
      likes: 0,
      timestamp: nil,
      imageUrls: imageUrls.isEmpty ? nil : imageUrls
    )

    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      request.httpBody = try JSONEncoder().encode(newPost)
      let _ = try await URLSession.shared.data(for: request)
      await fetchPosts()  // Refresh list
    } catch {
      print("Failed to create post: \(error)")
    }
  }

  // Upload image to media service
  private func uploadImage(_ image: UIImage) async -> String? {
    guard let url = URL(string: "\(baseURL)/media/upload") else { return nil }
    guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
    body.append("blog_post\r\n".data(using: .utf8)!)
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body

    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      if let result = try? JSONDecoder().decode(MediaUploadResponse.self, from: data),
         result.success,
         let mediaData = result.data {
        return mediaData.url
      }
    } catch {
      print("Failed to upload image: \(error)")
    }

    return nil
  }
}

// MARK: - Media Upload Response
struct MediaUploadResponse: Decodable {
  let success: Bool
  let data: MediaData?
}

struct MediaData: Decodable {
  let id: String
  let url: String
  let thumbnailUrl: String?

  enum CodingKeys: String, CodingKey {
    case id, url
    case thumbnailUrl = "thumbnail_url"
  }
}
