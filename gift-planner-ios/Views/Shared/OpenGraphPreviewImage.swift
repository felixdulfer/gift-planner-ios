import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class OpenGraphImageLoader: ObservableObject {
#if canImport(UIKit)
    @Published private(set) var image: UIImage?
#else
    @Published private(set) var image: Image?
#endif
    @Published private(set) var isLoading = false
    @Published private(set) var hasAttempted = false
    
    private let link: URL
    
    init(link: URL) {
        self.link = link
    }
    
    func load() {
        guard !isLoading, !hasAttempted else { return }
        
        isLoading = true
        
        Task {
            if let cached = await OpenGraphImageCache.shared.cachedImage(for: link) {
                await MainActor.run {
                    self.image = cached
                    self.isLoading = false
                    self.hasAttempted = true
                }
                return
            }
            
            do {
                if let fetchedImageURL = try await OpenGraphFetcher.imageURL(for: link),
                   let fetchedImage = try await Self.fetchImage(from: fetchedImageURL) {
                    await OpenGraphImageCache.shared.store(image: fetchedImage, for: link)
                    
                    await MainActor.run {
                        self.image = fetchedImage
                        self.isLoading = false
                        self.hasAttempted = true
                    }
                } else {
                    await OpenGraphImageCache.shared.store(image: nil, for: link)
                    
                    await MainActor.run {
                        self.isLoading = false
                        self.hasAttempted = true
                    }
                }
            } catch {
                await OpenGraphImageCache.shared.store(image: nil, for: link)
                
                await MainActor.run {
                    self.isLoading = false
                    self.hasAttempted = true
                }
            }
        }
    }
    
#if canImport(UIKit)
    private static func fetchImage(from url: URL) async throws -> UIImage? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue(OpenGraphFetcher.userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode) else {
            return nil
        }
        
        return UIImage(data: data)
    }
#else
    private static func fetchImage(from url: URL) async throws -> Image? {
        return nil
    }
#endif
}

struct OpenGraphPreviewImage: View {
    enum Style {
        case fullWidth
        case square(CGFloat)
    }
    
    private let link: URL
    private let style: Style
    @StateObject private var loader: OpenGraphImageLoader
    
    init(link: URL, style: Style = .fullWidth) {
        self.link = link
        self.style = style
        _loader = StateObject(wrappedValue: OpenGraphImageLoader(link: link))
    }
    
    var body: some View {
        ZStack {
#if canImport(UIKit)
            if let uiImage = loader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if loader.isLoading {
                placeholder
            } else if loader.hasAttempted {
                fallback
            } else {
                placeholder
            }
#else
            if let image = loader.image {
                image
                    .resizable()
                    .scaledToFill()
            } else if loader.isLoading {
                placeholder
            } else if loader.hasAttempted {
                fallback
            } else {
                placeholder
            }
#endif
        }
        .frame(width: frameWidth, height: frameHeight)
        .frame(maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
        .clipped()
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .onAppear {
            loader.load()
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            ProgressView()
        }
    }
    
    private var fallback: some View {
        ZStack {
            Color(.tertiarySystemBackground)
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.gray)
        }
    }
    
    private var frameWidth: CGFloat? {
        switch style {
        case .fullWidth:
            return nil
        case .square(let size):
            return size
        }
    }
    
    private var frameHeight: CGFloat? {
        switch style {
        case .fullWidth:
            return nil
        case .square(let size):
            return size
        }
    }
    
    private var maxWidth: CGFloat? {
        switch style {
        case .fullWidth:
            return .infinity
        case .square:
            return nil
        }
    }
    
    private var minHeight: CGFloat? {
        switch style {
        case .fullWidth:
            return 140
        case .square:
            return nil
        }
    }
    
    private var maxHeight: CGFloat? {
        switch style {
        case .fullWidth:
            return 160
        case .square:
            return nil
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .fullWidth:
            return Color(.secondarySystemBackground)
        case .square:
            return Color(.tertiarySystemBackground)
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .fullWidth:
            return 12
        case .square:
            return 10
        }
    }
}

struct OpenGraphPreviewImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OpenGraphPreviewImage(link: URL(string: "https://www.apple.com")!)
                .padding()
            
            OpenGraphPreviewImage(link: URL(string: "https://www.apple.com")!, style: .square(96))
        }
    }
}

