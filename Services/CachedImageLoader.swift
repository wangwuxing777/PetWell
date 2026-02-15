import SwiftUI
import Combine

// Shared memory cache to prevent reloading from disk on scroll
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let urlString: String
    private var cancellable: AnyCancellable?
    
    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    init(urlString: String) {
        self.urlString = urlString
        
        // 1. Check Memory Cache first (Instant)
        if let memoryImage = ImageCache.shared.get(forKey: urlString) {
            self.image = memoryImage
            self.isLoading = false
            return
        }
        
        // 2. Check Disk Cache (Fast IO)
        self.isLoading = true
        // Try to load synchronously first to avoid flash if file exists
        if let cachedImage = loadFromDisk() {
            self.image = cachedImage
            self.isLoading = false
            // Populate memory cache
            ImageCache.shared.set(cachedImage, forKey: urlString)
        } else {
            // 3. Download (Network)
            downloadImage()
        }
    }
    
    private func loadFromDisk() -> UIImage? {
        let fileURL = getFileURL(for: urlString)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL) {
                return UIImage(data: data)
            }
        }
        return nil
    }
    
    private func downloadImage() {
        guard let url = URL(string: urlString) else {
            self.isLoading = false
            return
        }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] downloadedImage in
                guard let self = self, let image = downloadedImage else { return }
                
                // Save to Memory Cache
                ImageCache.shared.set(image, forKey: self.urlString)
                
                self.image = image
                self.saveToDisk(image: image)
            })
    }
    
    private func saveToDisk(image: UIImage) {
        // Run on background thread
        DispatchQueue.global(qos: .background).async {
            let fileURL = self.getFileURL(for: self.urlString)
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func getFileURL(for urlString: String) -> URL {
        let data = urlString.data(using: .utf8)!
        let base64 = data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent(base64 + ".jpg")
    }
}

enum CachedAsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error?)
    
    var image: Image? {
        if case .success(let image) = self {
            return image
        }
        return nil
    }
    
    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

struct CachedAsyncImage<Content: View>: View {
    @StateObject private var loader: ImageLoader
    private let content: (CachedAsyncImagePhase) -> Content
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (CachedAsyncImagePhase) -> Content
    ) {
        self._loader = StateObject(wrappedValue: ImageLoader(urlString: url?.absoluteString ?? ""))
        self.content = content
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(.success(Image(uiImage: image)))
            } else if loader.isLoading {
                content(.empty)
            } else {
                content(.failure(loader.error))
            }
        }
    }
}
