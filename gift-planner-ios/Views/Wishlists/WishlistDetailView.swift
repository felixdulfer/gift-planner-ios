import SwiftUI

struct WishlistDetailView: View {
    @StateObject private var authService = AuthService()
    let wishlist: Wishlist
    let event: Event
    @State private var giftSuggestions: [GiftSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingAddGift = false
    
    var canEdit: Bool {
        guard let userId = authService.userId else { return false }
        return event.memberIds.contains(userId)
    }
    
    var body: some View {
        List {
            Section {
                Text(wishlist.name)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Section(header: Text("Gift Suggestions")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if giftSuggestions.isEmpty {
                    Text("No gift suggestions yet")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(giftSuggestions) { suggestion in
                        GiftSuggestionRow(
                            suggestion: suggestion,
                            canEdit: canEdit,
                            onToggleFavorite: { toggleFavorite(suggestion) },
                            onTogglePurchased: { togglePurchased(suggestion) }
                        )
                    }
                    .onDelete(perform: deleteSuggestions)
                }
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if canEdit {
                Section {
                    Button(action: { showingAddGift = true }) {
                        Label("Add Gift Suggestion", systemImage: "plus.circle")
                    }
                }
            }
        }
        .navigationTitle("Wishlist")
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: deleteWishlist) {
                            Label("Delete Wishlist", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGift) {
            AddGiftSuggestionView(wishlistId: wishlist.id ?? "", isPresented: $showingAddGift)
        }
        .onChange(of: showingAddGift) { oldValue, newValue in
            // Refresh when sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    await loadGiftSuggestions()
                }
            }
        }
        .task {
            await loadGiftSuggestions()
        }
        .refreshable {
            await loadGiftSuggestions()
        }
    }
    
    private func loadGiftSuggestions() async {
        guard let wishlistId = wishlist.id else {
            await MainActor.run {
                errorMessage = "Wishlist ID is missing"
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            print("Loading gift suggestions for wishlist: \(wishlistId)")
            let loadedSuggestions = try await FirestoreService.shared.getGiftSuggestions(for: wishlistId)
            print("Loaded \(loadedSuggestions.count) gift suggestions")
            await MainActor.run {
                self.giftSuggestions = loadedSuggestions
                self.isLoading = false
            }
        } catch {
            print("Error loading gift suggestions: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func deleteSuggestions(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let suggestion = giftSuggestions[index]
                guard let suggestionId = suggestion.id else { continue }
                
                do {
                    try await FirestoreService.shared.deleteGiftSuggestion(suggestionId: suggestionId)
                    await loadGiftSuggestions()
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func toggleFavorite(_ suggestion: GiftSuggestion) {
        guard let suggestionId = suggestion.id else { return }
        
        Task {
            do {
                try await FirestoreService.shared.toggleFavorite(suggestionId: suggestionId, isFavorited: !suggestion.isFavorited)
                await loadGiftSuggestions()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func togglePurchased(_ suggestion: GiftSuggestion) {
        guard let suggestionId = suggestion.id, let userId = authService.userId else { return }
        
        Task {
            do {
                if suggestion.isPurchased {
                    try await FirestoreService.shared.markAsNotPurchased(suggestionId: suggestionId)
                } else {
                    try await FirestoreService.shared.markAsPurchased(suggestionId: suggestionId, purchasedBy: userId)
                }
                await loadGiftSuggestions()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteWishlist() {
        guard let wishlistId = wishlist.id else { return }
        
        Task {
            do {
                try await FirestoreService.shared.deleteWishlist(wishlistId: wishlistId)
                await MainActor.run {
                    // Navigation will be handled automatically
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct GiftSuggestionRow: View {
    let suggestion: GiftSuggestion
    let canEdit: Bool
    let onToggleFavorite: () -> Void
    let onTogglePurchased: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.title)
                    .font(.headline)
                    .strikethrough(suggestion.isPurchased)
                
                Spacer()
                
                if suggestion.isFavorited {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                
                if suggestion.isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if let description = suggestion.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let link = suggestion.link, !link.isEmpty {
                Link(link, destination: URL(string: link) ?? URL(string: "https://example.com")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if canEdit {
                HStack {
                    Button(action: onToggleFavorite) {
                        Label(
                            suggestion.isFavorited ? "Unfavorite" : "Favorite",
                            systemImage: suggestion.isFavorited ? "heart.fill" : "heart"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: onTogglePurchased) {
                        Label(
                            suggestion.isPurchased ? "Mark as Not Purchased" : "Mark as Purchased",
                            systemImage: suggestion.isPurchased ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        WishlistDetailView(
            wishlist: Wishlist(eventId: "event1", name: "John's Gifts", createdBy: "user1"),
            event: Event(name: "Christmas 2025", createdBy: "user1", memberIds: ["user1"])
        )
    }
}

