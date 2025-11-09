import SwiftUI

struct CreateWishlistView: View {
    @StateObject private var authService = AuthService()
    let eventId: String
    @State private var wishlistName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    
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
                    isPresented = false
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

