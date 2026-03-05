//
//  BlogViewModel.swift
//  PetWell
//
//  Created for Blog API integration.
//

import Combine
import Foundation

@MainActor
class BlogViewModel: ObservableObject {
    @Published var posts: [BlogPost] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var errorMessage: String?

    private let apiBaseURL = "http://localhost:8000"
    private var currentPage = 1
    private let perPage = 10
    private var currentFeedType: FeedType = .explore
    private var cancellables = Set<AnyCancellable>()

    enum FeedType: String {
        case explore = "explore"
        case following = "following"
        case nearby = "nearby"
    }

    // MARK: - Fetch Posts

    func fetchPosts(type: FeedType) {
        currentFeedType = type
        currentPage = 1
        hasMore = true
        posts = []

        loadPosts()
    }

    // MARK: - Load More Posts (Pagination)

    func loadMorePosts() {
        guard !isLoading && hasMore else { return }

        currentPage += 1
        loadPosts()
    }

    // MARK: - Refresh Posts

    func refreshPosts() {
        currentPage = 1
        hasMore = true
        posts = []
        loadPosts()
    }

    // MARK: - Private Methods

    private func loadPosts() {
        guard let url = buildURL() else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: BlogPostsResponse.self, decoder: JSONDecoder.blogDecoder)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false

                    if case .failure(let error) = completion {
                        self.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    self.handleResponse(response)
                }
            )
            .store(in: &cancellables)
    }

    private func buildURL() -> URL? {
        var components = URLComponents(string: "\(apiBaseURL)/api/posts")

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(currentPage)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "type", value: currentFeedType.rawValue)
        ]

        components?.queryItems = queryItems
        return components?.url
    }

    private func handleResponse(_ response: BlogPostsResponse) {
        if currentPage == 1 {
            posts = response.posts
        } else {
            posts.append(contentsOf: response.posts)
        }

        // Check if there are more pages
        let loadedCount = posts.count
        hasMore = loadedCount < response.total
    }

    private func handleError(_ error: Error) {
        print("Blog API Error: \(error)")

        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, _):
                errorMessage = "Missing field: \(key)"
            case .typeMismatch(_, let context):
                errorMessage = "Type mismatch: \(context.debugDescription)"
            default:
                errorMessage = "Failed to parse response"
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "No internet connection"
            case .timedOut:
                errorMessage = "Request timed out"
            case .cannotConnectToHost:
                errorMessage = "Cannot connect to server"
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            errorMessage = "An unexpected error occurred"
        }
    }

    // MARK: - Like Post

    func likePost(postId: String) {
        guard let url = URL(string: "\(apiBaseURL)/api/posts/\(postId)/like") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if error == nil {
                    // Update local state
                    if let index = self?.posts.firstIndex(where: { $0.id == postId }) {
                        let post = self?.posts[index]
                        let updatedPost = BlogPost(
                            id: post?.id ?? "",
                            author: post?.author ?? PostAuthor(id: "", name: "", avatar: nil),
                            content: post?.content ?? "",
                            images: post?.images ?? [],
                            likes: (post?.likes ?? 0) + 1,
                            comments: post?.comments ?? 0,
                            createdAt: post?.createdAt ?? Date()
                        )
                        self?.posts[index] = updatedPost
                    }
                }
            }
        }.resume()
    }

    // MARK: - Create Post

    func createPost(content: String, images: [String], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)/api/posts") else {
            completion(false)
            return
        }

        let requestBody = CreatePostRequest(content: content, images: images)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try JSONEncoder.blogEncoder.encode(requestBody)
        } catch {
            errorMessage = "Failed to encode request"
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    completion(false)
                    return
                }

                if (200...299).contains(httpResponse.statusCode) {
                    // Refresh posts after successful creation
                    self?.refreshPosts()
                    completion(true)
                } else {
                    self?.errorMessage = "Server error: \(httpResponse.statusCode)"
                    completion(false)
                }
            }
        }.resume()
    }
}
