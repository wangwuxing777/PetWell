//
//  ContentView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import SwiftUI
import Combine
import PhotosUI
import UIKit

// MARK: - Blog Models (Temporary placement for build)
// TODO: Move to separate file and add to Xcode project

struct BlogPostAPI: Codable, Identifiable {
    let id: String
    let author: PostAuthor
    let content: String
    let images: [PostImage]
    let likes: Int
    let comments: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case content
        case images
        case likes
        case comments
        case createdAt = "created_at"
    }
}

struct PostAuthor: Codable {
    let id: String
    let name: String
    let avatar: String?
}

struct PostImage: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct BlogPostsResponse: Codable {
    let posts: [BlogPostAPI]
    let total: Int
    let page: Int
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case posts
        case total
        case page
        case perPage = "per_page"
    }
}

struct CreatePostRequest: Codable {
    let content: String
    let images: [String]
}

extension JSONDecoder {
    static var blogDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var blogEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

// MARK: - BlogViewModel (Temporary placement for build)

@MainActor
class BlogViewModel: ObservableObject {
    @Published var posts: [BlogPostAPI] = []
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

    func fetchPosts(type: FeedType) {
        currentFeedType = type
        currentPage = 1
        hasMore = true
        posts = []
        loadPosts()
    }

    func loadMorePosts() {
        guard !isLoading && hasMore else { return }
        currentPage += 1
        loadPosts()
    }

    func refreshPosts() {
        currentPage = 1
        hasMore = true
        posts = []
        loadPosts()
    }

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
                    if self.currentPage == 1 {
                        self.posts = response.posts
                    } else {
                        self.posts.append(contentsOf: response.posts)
                    }
                    let loadedCount = self.posts.count
                    self.hasMore = loadedCount < response.total
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

    private func handleError(_ error: Error) {
        print("Blog API Error: \(error)")
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "No internet connection"
            case .timedOut:
                errorMessage = "Request timed out"
            case .cannotConnectToHost:
                errorMessage = "Cannot connect to server"
            default:
                errorMessage = "Network error"
            }
        } else {
            errorMessage = "Failed to load posts"
        }
    }

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

enum Tab: Hashable {
  case shop, medical, insurance, profile, blog
}

enum GuideAction: String {
  case blogPostTapped
  case shopOpenedFilter
  case insuranceScrolled
  case insuranceCompareTapped
  case insuranceComparedChanged
  case medicalOpenedMap
  case profileTappedAddPet
}

struct GuideStep: Identifiable {
  let id = UUID()
  let tab: Tab
  let title: String
  let message: String
  let requiredAction: GuideAction?
}

final class GuideManager: ObservableObject {
  @Published var isActive = false
  @Published var currentIndex = 0

  private let completedKey = "hasCompletedContextualGuideV1"

  let steps: [GuideStep] = [
    GuideStep(
      tab: .blog,
      title: "Blog",
      message: "Tap the + button at the top-right to create your first post.",
      requiredAction: .blogPostTapped
    ),
    GuideStep(
      tab: .shop,
      title: "Shop · For You",
      message: "Open Filter to try the For my pet recommendation (future core feature).",
      requiredAction: .shopOpenedFilter
    ),
    GuideStep(
      tab: .insurance,
      title: "Insurance",
      message: "Scroll down to learn key insurance basics.",
      requiredAction: .insuranceScrolled
    ),
    GuideStep(
      tab: .insurance,
      title: "Insurance Compare",
      message: "Tap Compare to open side-by-side plan comparison.",
      requiredAction: .insuranceCompareTapped
    ),
    GuideStep(
      tab: .insurance,
      title: "Use Compare",
      message: "Try changing a product or switch to scenario mode to compare by case.",
      requiredAction: .insuranceComparedChanged
    ),
    GuideStep(
      tab: .medical,
      title: "Medical",
      message: "Use the clinic button at top-right to open testclinics and book a test medical service.",
      requiredAction: .medicalOpenedMap
    ),
    GuideStep(
      tab: .profile,
      title: "Profile",
      message: "Tap + to add your pet profile and complete records.",
      requiredAction: .profileTappedAddPet
    ),
  ]

  var currentStep: GuideStep? {
    guard isActive, currentIndex < steps.count else { return nil }
    return steps[currentIndex]
  }

  var progressText: String {
    "\(min(currentIndex + 1, steps.count))/\(steps.count)"
  }

  func startIfNeeded() {
    let hasCompleted = UserDefaults.standard.bool(forKey: completedKey)
    if !hasCompleted {
      isActive = true
      currentIndex = 0
    }
  }

  func skip() {
    complete()
  }

  func next() {
    guard isActive else { return }
    if currentIndex >= steps.count - 1 {
      complete()
    } else {
      currentIndex += 1
    }
  }

  func mark(_ action: GuideAction) {
    guard let step = currentStep else { return }
    guard step.requiredAction == action else { return }
    next()
  }

  func complete() {
    isActive = false
    UserDefaults.standard.set(true, forKey: completedKey)
  }

  func replay() {
    UserDefaults.standard.set(false, forKey: completedKey)
    isActive = true
    currentIndex = 0
  }
}

private struct GuideOverlayCard: View {
  let step: GuideStep
  let progressText: String
  let onSkip: () -> Void
  let onNext: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(step.title)
          .font(.headline.weight(.bold))
        Spacer()
        Text(progressText)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Text(step.message)
        .font(.subheadline)
        .foregroundColor(.secondary)

      HStack {
        Button("Skip") { onSkip() }
          .font(.subheadline.weight(.semibold))
          .foregroundColor(.secondary)

        Spacer()

        Button("Next") {
          onNext()
        }
        .font(.subheadline.weight(.bold))
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.blue, in: Capsule())
      }
    }
    .padding(16)
    .background(
      LinearGradient(
        colors: [Color.white.opacity(0.20), Color.white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ),
      in: RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [Color.white.opacity(0.70), Color.white.opacity(0.24)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 10)
  }
}

struct ContentView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @State private var selectedTab: Tab = .blog  // Default to Blog as per request "Blog button to the first one"
  @State private var isGuardianPresented = false
  @State private var guardianButtonPosition: CGPoint = .zero
  @State private var guardianButtonDragOffset: CGSize = .zero
  @StateObject private var blogService = BlogService.shared
  @StateObject private var guideManager = GuideManager()

  var body: some View {
    GeometryReader { geo in
      ZStack {
        TabView(selection: $selectedTab) {
          BlogView()
            .environmentObject(blogService)  // Inject service
            .environmentObject(guideManager)
            .tabItem {
              Label(
                languageManager.isChinese ? "日誌" : "Blog",
                systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(Tab.blog)

          ShopView()
            .environmentObject(guideManager)
            .tabItem { Label(languageManager.isChinese ? "商店" : "Shop", systemImage: "bag") }
            .tag(Tab.shop)

          VaccineView()
            .environmentObject(guideManager)
            .tabItem {
              Label(languageManager.isChinese ? "醫療" : "Medical", systemImage: "cross.case")
            }
            .tag(Tab.medical)

          InsuranceView()
            .environmentObject(guideManager)
            .tabItem {
              Label(languageManager.isChinese ? "保險" : "Insurance", systemImage: "shield")
            }
            .tag(Tab.insurance)

          RecordsView()
            .environmentObject(guideManager)
            .tabItem {
              Label(languageManager.isChinese ? "檔案" : "Profile", systemImage: "person.circle")
            }
            .tag(Tab.profile)
        }

        // Floating PetWell Guardian button (draggable)
        Button {
          isGuardianPresented = true
        } label: {
          Image(systemName: "sparkles")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .padding(14)
            .background(Circle().fill(Color.accentColor))
            .shadow(radius: 6)
            .accessibilityLabel("PetWell Guardian")
        }
        .position(
          x: guardianButtonPosition.x + guardianButtonDragOffset.width,
          y: guardianButtonPosition.y + guardianButtonDragOffset.height
        )
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              guardianButtonDragOffset = value.translation
            }
            .onEnded { value in
              let buttonRadius: CGFloat = 28  // approx half of button diameter
              let padding: CGFloat = 12

              var newX = guardianButtonPosition.x + value.translation.width
              var newY = guardianButtonPosition.y + value.translation.height

              // Clamp inside the screen
              newX = min(max(newX, buttonRadius + padding), geo.size.width - buttonRadius - padding)
              newY = min(
                max(newY, buttonRadius + padding), geo.size.height - buttonRadius - padding)

              guardianButtonPosition = CGPoint(x: newX, y: newY)
              guardianButtonDragOffset = .zero
            }
        )
        .onAppear {
          // Set default position (bottom-right) once
          if guardianButtonPosition == .zero {
            let buttonRadius: CGFloat = 28
            let padding: CGFloat = 18
            guardianButtonPosition = CGPoint(
              x: geo.size.width - buttonRadius - padding,
              y: geo.size.height - buttonRadius - padding
            )
          }
        }

      }
    }
    .sheet(isPresented: $isGuardianPresented) {
      RAGChatView(
        contextString: languageManager.isChinese ? "寵物醫療諮詢" : "Pet medical consultation",
        initialModel: .medical,
        isPresented: $isGuardianPresented
      )
    }
  }
}

// MARK: - Placeholder screens (MVP stubs)

private struct HomeView: View {
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("PetWell")
          .font(.largeTitle).bold()

        Text("Shop (unused stub)")
          .font(.title3)

        Text("Next: pet overview + reminders.")
          .foregroundStyle(.secondary)

        Spacer()
      }
      .padding()
      .navigationTitle("Shop")
    }
  }
}

private struct ClinicView: View {
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("Vaccination & Medical (MVP stub)")
          .font(.title2).bold()

        Text("Next: clinic list + booking flow.")
          .foregroundStyle(.secondary)

        Spacer()
      }
      .padding()
      .navigationTitle("Medical")
    }
  }
}

private struct InsuranceView: View {
  var body: some View {
    InsuranceLandingView()
  }
}



#Preview {
  ContentView()
}

// MARK: - Blog

struct BlogPost: Identifiable {
  let id = UUID()
  let authorName: String
  let authorAvatar: String  // SF Symbol or Image name
  let title: String
  let imageColor: Color  // Placeholder for image
  let imageHeight: CGFloat  // For masonry layout
  let likes: Int
  let isLiked: Bool
}

// Consolidated Blog logic using new BlogViewModel
struct BlogView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var guideManager: GuideManager
  @StateObject private var viewModel = BlogViewModel()
  @State private var showingPostSheet = false

  // Convert new BlogPostAPI to UI-compatible format
  var leftColumn: [BlogPostAPI] {
    viewModel.posts.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
  }

  var rightColumn: [BlogPostAPI] {
    viewModel.posts.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Top Custom Navigation Bar
        HStack(spacing: 20) {

          Spacer()

          Text(languageManager.isChinese ? "關注" : "Following")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.gray)

          VStack(spacing: 4) {
            Text(languageManager.isChinese ? "探索" : "Explore")
              .font(.system(size: 17, weight: .bold))
              .foregroundColor(.black)

            RoundedRectangle(cornerRadius: 2)
              .fill(Color.blue)
              .frame(width: 30, height: 3)
          }

          Text(languageManager.isChinese ? "附近" : "Nearby")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.gray)

          Spacer()

          Button(action: {
            showingPostSheet = true
            guideManager.mark(.blogPostTapped)
          }) {
            Image(systemName: "plus.square")
              .font(.system(size: 22))
              .foregroundColor(.black)
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color.white)

        // Error Message
        if let errorMessage = viewModel.errorMessage {
          HStack {
            Image(systemName: "exclamationmark.triangle")
              .foregroundColor(.orange)
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.secondary)
            Spacer()
            Button("Retry") {
              viewModel.refreshPosts()
            }
            .font(.caption)
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .background(Color.orange.opacity(0.1))
        }

        // Content
        if viewModel.isLoading && viewModel.posts.isEmpty {
          // Loading State
          VStack {
            Spacer()
            ProgressView("Loading posts...")
              .controlSize(.large)
            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.posts.isEmpty {
          // Empty State
          VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
              .font(.system(size: 50))
              .foregroundColor(.gray)
            Text("No posts yet")
              .font(.headline)
              .foregroundColor(.gray)
            Text("Be the first to share!")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 100)
          .frame(maxWidth: .infinity)
        } else {
          // Posts Feed
          ScrollView {
            HStack(alignment: .top, spacing: 10) {
              // Left Column
              LazyVStack(spacing: 10) {
                ForEach(Array(leftColumn.enumerated()), id: \.element.id) { index, post in
                  NewBlogCard(post: post, index: index * 2)
                }
              }

              // Right Column
              LazyVStack(spacing: 10) {
                ForEach(Array(rightColumn.enumerated()), id: \.element.id) { index, post in
                  NewBlogCard(post: post, index: index * 2 + 1)
                }
              }
            }
            .padding(10)
          }
          .accessibilityIdentifier("BlogFeedView")
          .refreshable {
            viewModel.refreshPosts()
          }
        }
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showingPostSheet) {
        NewPostBlogView(viewModel: viewModel)
      }
    }
    .onAppear {
      // Initial fetch
      viewModel.fetchPosts(type: .explore)
    }
  }
}

struct BlogCard: View {
  let post: BlogPostModel
  let index: Int

  // Helper to produce color from string
  var imageColor: Color {
    switch post.imageColor {
    case "mint": return .mint
    case "orange": return .orange
    case "pink": return .pink
    case "yellow": return .yellow
    case "green": return .green
    default: return .blue
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Image Placeholder
      Rectangle()
        .fill(imageColor)
        .frame(height: 180)  // Fixed height for simplicity or random interaction
        .overlay(
          Image(systemName: "photo")
            .foregroundColor(.white.opacity(0.5))
            .font(.largeTitle)
        )

      VStack(alignment: .leading, spacing: 8) {
        Text(post.title)
          .font(.system(size: 14, weight: .medium))
          .lineLimit(2)
          .foregroundColor(.black)
          .accessibilityIdentifier("BlogPostTitle_\(index)")

        HStack {
          HStack(spacing: 4) {
            Image(systemName: post.authorAvatar)
              .resizable()
              .scaledToFill()
              .frame(width: 16, height: 16)
              .clipShape(Circle())
              .foregroundColor(.gray)

            Text(post.authorName)
              .font(.system(size: 10))
              .foregroundColor(.gray)
              .lineLimit(1)
          }

          Spacer()

          HStack(spacing: 4) {
            Image(systemName: "heart")
              .font(.system(size: 12))
              .foregroundColor(.gray)

            Text("\(post.likes)")
              .font(.system(size: 10))
              .foregroundColor(.gray)
          }
        }
      }
      .padding(8)
      .background(Color.white)
    }
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    .accessibilityIdentifier("BlogPostCell_\(index)")
  }
}

// MARK: - New Blog Components (using BlogViewModel)

struct NewBlogCard: View {
  let post: BlogPostAPI
  let index: Int

  // Helper to produce color from string (based on author id)
  var imageColor: Color {
    let colors: [Color] = [.mint, .orange, .pink, .yellow, .green, .blue, .purple, .red]
    let hash = post.author.id.hashValue
    return colors[abs(hash) % colors.count]
  }

  var body: some View {
    VStack(spacing: 0) {
      // Image Placeholder or First Image
      if let firstImage = post.images.first {
        AsyncImage(url: URL(string: firstImage.url)) { phase in
          switch phase {
          case .empty:
            Rectangle()
              .fill(imageColor)
              .overlay(ProgressView())
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure:
            Rectangle()
              .fill(imageColor)
              .overlay(
                Image(systemName: "photo")
                  .foregroundColor(.white.opacity(0.5))
                  .font(.largeTitle)
              )
          @unknown default:
            EmptyView()
          }
        }
        .frame(height: 180)
        .clipped()
      } else {
        Rectangle()
          .fill(imageColor)
          .frame(height: 180)
          .overlay(
            Image(systemName: "photo")
              .foregroundColor(.white.opacity(0.5))
              .font(.largeTitle)
          )
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(post.content)
          .font(.system(size: 14, weight: .medium))
          .lineLimit(2)
          .foregroundColor(.black)
          .accessibilityIdentifier("BlogPostTitle_\(index)")

        HStack {
          HStack(spacing: 4) {
            if let avatar = post.author.avatar, let url = URL(string: avatar) {
              AsyncImage(url: url) { image in
                image
                  .resizable()
                  .scaledToFill()
              } placeholder: {
                Image(systemName: "person.circle")
                  .resizable()
              }
              .frame(width: 16, height: 16)
              .clipShape(Circle())
            } else {
              Image(systemName: "person.circle")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.gray)
            }

            Text(post.author.name)
              .font(.system(size: 10))
              .foregroundColor(.gray)
              .lineLimit(1)
          }

          Spacer()

          HStack(spacing: 4) {
            Image(systemName: "heart")
              .font(.system(size: 12))
              .foregroundColor(.gray)

            Text("\(post.likes)")
              .font(.system(size: 10))
              .foregroundColor(.gray)
          }
        }
      }
      .padding(8)
      .background(Color.white)
    }
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    .accessibilityIdentifier("BlogPostCell_\(index)")
  }
}

struct NewPostBlogView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @Environment(\.dismiss) var dismiss
  @ObservedObject var viewModel: BlogViewModel
  @State private var content = ""
  @State private var isSubmitting = false
  @State private var showError = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Custom Header
        HStack {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .font(.system(size: 20))
              .foregroundColor(.black)
          }
          Spacer()
          Text(languageManager.isChinese ? "發布帖子" : "Create Post")
            .font(.headline)
          Spacer()
          Button(action: submitPost) {
            if isSubmitting {
              ProgressView()
                .controlSize(.small)
            } else {
              Text(languageManager.isChinese ? "發布" : "Post")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(content.isEmpty ? .gray : .blue)
            }
          }
          .disabled(content.isEmpty || isSubmitting)
        }
        .padding()

        // Content Input
        TextEditor(text: $content)
          .font(.body)
          .padding(.horizontal)
          .placeholder(when: content.isEmpty) {
            Text(languageManager.isChinese ? "分享你的寵物故事..." : "Share your pet story...")
              .foregroundColor(.gray)
              .padding(.horizontal, 20)
              .padding(.vertical, 8)
          }

        Spacer()
      }
      .alert("Error", isPresented: $showError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(viewModel.errorMessage ?? "Failed to create post")
      }
    }
  }

  private func submitPost() {
    isSubmitting = true
    viewModel.createPost(content: content, images: []) { success in
      isSubmitting = false
      if success {
        dismiss()
      } else {
        showError = true
      }
    }
  }
}

// MARK: - TextEditor Placeholder Extension

extension View {
  func placeholder<Content: View>(
    when shouldShow: Bool,
    alignment: Alignment = .topLeading,
    @ViewBuilder placeholder: () -> Content
  ) -> some View {
    ZStack(alignment: alignment) {
      placeholder().opacity(shouldShow ? 1 : 0)
      self
    }
  }
}

// Ensure PostBlogView is kept or updated if needed, heavily simplified for this request as we focus on list display
struct PostBlogView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var blogService: BlogService
  @Environment(\.dismiss) var dismiss
  @State private var title = ""
  @State private var content = ""

  // Image Picker State
  @State private var photoItems: [PhotosPickerItem] = []
  @State private var selectedImages: [UIImage] = []
  @State private var isShowingImagePicker = false

  // Tags State
  @State private var showTagsSheet = false
  @State private var selectedTopics: [BlogTopic] = []
  @State private var selectedUsers: [BlogUser] = []

  var body: some View {
    VStack(spacing: 0) {
      // Custom Header
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20))
            .foregroundColor(.black)
        }
        Spacer()
      }
      .padding(.horizontal)
      .padding(.top, 16)
      .padding(.bottom, 8)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {

          // Image Selection Area with PhotosPicker
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              // Add Photo Button
              PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: 10,
                matching: .images
              ) {
                VStack {
                  Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                  Text(languageManager.isChinese ? "添加相片" : "Add Photo")
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
              }

              // Selected Images Preview
              ForEach(selectedImages.indices, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                  Image(uiImage: selectedImages[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(12)

                  // Delete Button
                  Button(action: {
                    selectedImages.remove(at: index)
                    if index < photoItems.count {
                      photoItems.remove(at: index)
                    }
                  }) {
                    Image(systemName: "xmark.circle.fill")
                      .font(.system(size: 20))
                      .foregroundColor(.white)
                      .background(Circle().fill(Color.black.opacity(0.5)))
                  }
                  .offset(x: 8, y: -8)
                }
              }
            }
            .padding(.horizontal)
          }
          .onChange(of: photoItems) { _, newItems in
            // Load images from selected items
            selectedImages.removeAll()
            for item in newItems {
              Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                  await MainActor.run {
                    selectedImages.append(image)
                  }
                }
              }
            }
          }

          // Title Input
          TextField(languageManager.isChinese ? "加入標題" : "Add a title", text: $title)
            .font(.system(size: 20, weight: .bold))  // Larger font for title
            .padding(.horizontal)

          Divider().padding(.horizontal)

          // Content Input
          ZStack(alignment: .topLeading) {
            if content.isEmpty {
              Text(languageManager.isChinese ? "加入內文" : "Add text")
                .foregroundColor(.gray.opacity(0.6))
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            TextEditor(text: $content)
              .frame(minHeight: 150)
              .scrollContentBackground(.hidden)  // Remove default background
          }
          .padding(.horizontal)

          // Tags Row
          HStack(spacing: 12) {
            Button {
              showTagsSheet = true
            } label: {
              TagButton(icon: "number", text: languageManager.isChinese ? "話題" : "Topic")
            }

            Button {
              showTagsSheet = true
            } label: {
              TagButton(icon: "at", text: languageManager.isChinese ? "用戶" : "User")
            }

            Button {
              showTagsSheet = true
            } label: {
              TagButton(icon: "chart.bar", text: languageManager.isChinese ? "投票" : "Poll")
            }
          }
          .padding(.horizontal)
          .sheet(isPresented: $showTagsSheet) {
            BlogTagsView(isPresented: $showTagsSheet)
          }

          Divider()

          // Options List
          VStack(spacing: 0) {
            OptionRow(
              icon: "mappin.and.ellipse", text: languageManager.isChinese ? "加入地點" : "Tag Location",
              detail: languageManager.isChinese ? "香港公園" : "Hong Kong Park")
            Divider().padding(.leading, 40)
            OptionRow(
              icon: "lock.open", text: languageManager.isChinese ? "公開" : "Public",
              detail: languageManager.isChinese ? "所有人" : "Everyone")
            Divider().padding(.leading, 40)
            OptionRow(
              icon: "square.grid.2x2", text: languageManager.isChinese ? "加入小工具" : "Add widgets",
              detail: "")
            Divider().padding(.leading, 40)
            OptionRow(
              icon: "gearshape", text: languageManager.isChinese ? "進階設定" : "Advanced options",
              detail: "")
          }
          .padding(.horizontal)
        }
        .padding(.bottom, 100)  // Space for bottom bar
      }

      // Bottom Bar
      VStack(spacing: 0) {
        Divider()
        HStack {
          Button(action: {
            // Draft action
          }) {
            Text(languageManager.isChinese ? "存草稿" : "Save draft")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.black)
              .padding(.vertical, 12)
              .padding(.horizontal, 24)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(24)
          }

          Spacer()

          Button(action: {
            Task {
              await blogService.createPost(title: title, content: content, images: selectedImages)
              dismiss()
            }
          }) {
            Text(languageManager.isChinese ? "發布" : "Post")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.white)
              .padding(.vertical, 12)
              .padding(.horizontal, 48)
              .background(Color.blue)  // Standard app blue
              .cornerRadius(24)
          }
        }
        .padding()
      }
      .background(Color.white)
    }
  }
}

struct TagButton: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.system(size: 12))
      Text(text)
        .font(.system(size: 14))
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(16)
    .foregroundColor(.black)
  }
}

struct OptionRow: View {
  let icon: String
  let text: String
  let detail: String

  var body: some View {
    HStack {
      Image(systemName: icon)
        .frame(width: 24)
        .foregroundColor(.black)

      Text(text)
        .foregroundColor(.black)

      Spacer()

      if !detail.isEmpty {
        Text(detail)
          .font(.system(size: 14))
          .foregroundColor(.gray)
      }

      Image(systemName: "chevron.right")
        .font(.system(size: 14))
        .foregroundColor(.gray.opacity(0.5))
    }
    .padding(.vertical, 16)
  }
}
