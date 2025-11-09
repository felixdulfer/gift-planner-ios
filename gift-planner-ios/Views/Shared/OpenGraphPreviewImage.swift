import SwiftUI

@MainActor
final class OpenGraphImageLoader: ObservableObject {
    @Published private(set) var imageURL: URL?
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
            if let cached = await OpenGraphImageCache.shared.cachedImageURL(for: link) {
                await MainActor.run {
                    self.imageURL = cached
                    self.isLoading = false
                    self.hasAttempted = true
                }
                return
            }
            
            do {
                let fetchedImageURL = try await OpenGraphFetcher.imageURL(for: link)
                await OpenGraphImageCache.shared.store(imageURL: fetchedImageURL, for: link)
                
                await MainActor.run {
                    self.imageURL = fetchedImageURL
                    self.isLoading = false
                    self.hasAttempted = true
                }
            } catch {
                await OpenGraphImageCache.shared.store(imageURL: nil, for: link)
                
                await MainActor.run {
                    self.isLoading = false
                    self.hasAttempted = true
                }
            }
        }
    }
}

struct OpenGraphPreviewImage: View {
    private let link: URL
    @StateObject private var loader: OpenGraphImageLoader
    
    init(link: URL) {
        self.link = link
        _loader = StateObject(wrappedValue: OpenGraphImageLoader(link: link))
    }
    
    var body: some View {
        ZStack {
            if let imageURL = loader.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else if loader.isLoading {
                placeholder
            } else if loader.hasAttempted {
                fallback
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 160)
        .clipped()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
}

struct OpenGraphPreviewImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OpenGraphPreviewImage(link: URL(string: "https://www.apple.com")!)
                .padding()
        }
    }
}

