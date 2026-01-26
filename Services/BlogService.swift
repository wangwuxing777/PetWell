import Combine
import Foundation

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

  func createPost(title: String, content: String) async {
    guard let user = currentUser else { return }
    guard let url = URL(string: "\(baseURL)/posts") else { return }

    let newPost = BlogPostModel(
      id: "",  // Server assigns ID
      authorName: user.name,
      authorAvatar: "person.circle.fill",
      title: title,
      content: content,
      imageColor: "blue",
      likes: 0,
      timestamp: nil
    )

    var request = URLRequest(url: url)
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
}
