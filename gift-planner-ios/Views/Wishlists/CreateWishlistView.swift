import SwiftUI

struct CreateWishlistView: View {
    @StateObject private var authService = AuthService()
    let eventId: String
    @State private var wishlistName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    var onWishlistCreated: ((String) -> Void)?
    
    init(eventId: String, isPresented: Binding<Bool>, onWishlistCreated: ((String) -> Void)? = nil) {
        self.eventId = eventId
        self._isPresented = isPresented
        self.onWishlistCreated = onWishlistCreated
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
                    Button(action: createWishlist) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("Create Wishlist")
                        }
                    }
                    .disabled(isLoading || wishlistName.isEmpty)
                }
            }
            .navigationTitle("New Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func createWishlist() {
        guard let userId = authService.userId else {
            errorMessage = "You must be signed in to create a wishlist"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let wishlist = Wishlist(
            eventId: eventId,
            name: wishlistName,
            createdBy: userId
        )
        
        Task {
            do {
                _ = try await FirestoreService.shared.createWishlist(wishlist)
                await MainActor.run {
                    isLoading = false
                    let createdWishlistName = wishlistName
                    isPresented = false
                    // Call callback after dismissing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onWishlistCreated?(createdWishlistName)
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
    CreateWishlistView(eventId: "event1", isPresented: .constant(true))
}

