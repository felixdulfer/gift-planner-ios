import SwiftUI

struct WishlistDetailView: View {
    @StateObject private var authService = AuthService()
    let wishlist: Wishlist
    let event: Event
    @State private var currentWishlist: Wishlist
    @State private var giftSuggestions: [GiftSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingAddGift = false
    @State private var showingEditWishlist = false
    @State private var selectedSuggestion: GiftSuggestion?
    @State private var showingEditSuggestion = false
    @State private var toastMessage: String?
    
    init(wishlist: Wishlist, event: Event) {
        self.wishlist = wishlist
        self.event = event
        self._currentWishlist = State(initialValue: wishlist)
    }
    
    var canEdit: Bool {
        guard let userId = authService.userId else { return false }
        return event.memberIds.contains(userId)
    }
    
    var body: some View {
        List {
            Section {
                Text(currentWishlist.name)
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
                            onTogglePurchased: { togglePurchased(suggestion) },
                            onTap: {
                                selectedSuggestion = suggestion
                                showingEditSuggestion = true
                            }
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
                        Button(action: { showingEditWishlist = true }) {
                            Label("Edit Wishlist", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            Task {
                                await deleteWishlist()
                            }
                        }) {
                            Label("Delete Wishlist", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGift) {
            AddGiftSuggestionView(
                wishlistId: currentWishlist.id ?? "",
                isPresented: $showingAddGift,
                onGiftAdded: { giftTitle in
                    toastMessage = "Gift \"\(giftTitle)\" added"
                    Task {
                        await loadGiftSuggestions()
                    }
                }
            )
        }
        .onChange(of: showingAddGift) { oldValue, newValue in
            // Refresh when sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    await loadGiftSuggestions()
                }
            }
        }
        .onChange(of: showingEditSuggestion) { oldValue, newValue in
            if oldValue == true && newValue == false {
                selectedSuggestion = nil
            }
        }
        .sheet(isPresented: $showingEditWishlist) {
            EditWishlistView(
                wishlist: currentWishlist,
                isPresented: $showingEditWishlist,
                onWishlistUpdated: {
                    toastMessage = "Wishlist updated"
                    Task {
                        await loadWishlist()
                        await loadGiftSuggestions()
                    }
                }
            )
        }
        .sheet(isPresented: $showingEditSuggestion) {
            if let suggestion = selectedSuggestion {
                EditGiftSuggestionView(
                    suggestion: suggestion,
                    canEdit: canEdit,
                    isPresented: $showingEditSuggestion,
                    onSuggestionUpdated: { updatedSuggestion in
                        toastMessage = "Gift \"\(updatedSuggestion.title)\" updated"
                        selectedSuggestion = updatedSuggestion
                        Task {
                            await loadGiftSuggestions()
                        }
                    }
                )
            } else {
                EmptyView()
            }
        }
        .task {
            await loadGiftSuggestions()
        }
        .refreshable {
            await loadGiftSuggestions()
        }
        .toast(message: $toastMessage)
    }
    
    private func loadGiftSuggestions() async {
        guard let wishlistId = currentWishlist.id else {
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
    
    private func loadWishlist() async {
        guard let wishlistId = currentWishlist.id else { return }
        
        do {
            let updatedWishlist = try await FirestoreService.shared.getWishlist(wishlistId: wishlistId)
            await MainActor.run {
                self.currentWishlist = updatedWishlist
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
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
    
    private func deleteWishlist() async {
        guard let wishlistId = currentWishlist.id else { return }
        
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

struct GiftSuggestionRow: View {
    let suggestion: GiftSuggestion
    let canEdit: Bool
    let onToggleFavorite: () -> Void
    let onTogglePurchased: () -> Void
    let onTap: () -> Void
    
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
                HStack(spacing: 16) {
                    Button(action: onToggleFavorite) {
                        HStack(spacing: 4) {
                            Image(systemName: suggestion.isFavorited ? "heart.fill" : "heart")
                                .font(.caption)
                            Text(suggestion.isFavorited ? "Unfavorite" : "Favorite")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: onTogglePurchased) {
                        HStack(spacing: 4) {
                            Image(systemName: suggestion.isPurchased ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                            Text(suggestion.isPurchased ? "Mark as Not Purchased" : "Mark as Purchased")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
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

