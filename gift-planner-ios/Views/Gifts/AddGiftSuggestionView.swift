import SwiftUI

struct AddGiftSuggestionView: View {
    @StateObject private var authService = AuthService()
    let wishlistId: String
    @State private var title = ""
    @State private var description = ""
    @State private var link = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    var onGiftAdded: ((String) -> Void)?
    
    init(wishlistId: String, isPresented: Binding<Bool>, onGiftAdded: ((String) -> Void)? = nil) {
        self.wishlistId = wishlistId
        self._isPresented = isPresented
        self.onGiftAdded = onGiftAdded
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .textContentType(.none)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .textContentType(.none)
                    
                    TextField("Link (optional)", text: $link)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: addGiftSuggestion) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("Add Gift")
                        }
                    }
                    .disabled(isLoading || title.isEmpty)
                }
            }
            .navigationTitle("Add Gift")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func addGiftSuggestion() {
        guard let userId = authService.userId else {
            errorMessage = "You must be signed in to add a gift suggestion"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let suggestion = GiftSuggestion(
            wishlistId: wishlistId,
            title: title,
            description: description.isEmpty ? nil : description,
            link: link.isEmpty ? nil : link,
            suggestedBy: userId
        )
        
        Task {
            do {
                _ = try await FirestoreService.shared.createGiftSuggestion(suggestion)
                await MainActor.run {
                    isLoading = false
                    let createdTitle = title
                    isPresented = false
                    // Call callback after dismissing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onGiftAdded?(createdTitle)
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
    AddGiftSuggestionView(wishlistId: "wishlist1", isPresented: .constant(true))
}

