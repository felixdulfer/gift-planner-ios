import SwiftUI

struct EditWishlistView: View {
    let wishlist: Wishlist
    @State private var wishlistName: String
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    var onWishlistUpdated: (() -> Void)?
    
    init(wishlist: Wishlist, isPresented: Binding<Bool>, onWishlistUpdated: (() -> Void)? = nil) {
        self.wishlist = wishlist
        self._isPresented = isPresented
        self.onWishlistUpdated = onWishlistUpdated
        self._wishlistName = State(initialValue: wishlist.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Wishlist Name", text: $wishlistName)
                        .textContentType(.none)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: updateWishlist) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("Save Changes")
                        }
                    }
                    .disabled(isLoading || wishlistName.isEmpty)
                }
            }
            .navigationTitle("Edit Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func updateWishlist() {
        guard let wishlistId = wishlist.id else {
            errorMessage = "Wishlist ID is missing"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        var updatedWishlist = wishlist
        updatedWishlist.name = wishlistName
        
        Task {
            do {
                try await FirestoreService.shared.updateWishlist(updatedWishlist)
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onWishlistUpdated?()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    EditWishlistView(
        wishlist: Wishlist(eventId: "event1", name: "John's Gifts", createdBy: "user1"),
        isPresented: .constant(true)
    )
}

