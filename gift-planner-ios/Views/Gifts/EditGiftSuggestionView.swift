import SwiftUI

struct EditGiftSuggestionView: View {
    let suggestion: GiftSuggestion
    let canEdit: Bool
    @Binding var isPresented: Bool
    var onSuggestionUpdated: (GiftSuggestion) -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var link: String
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    init(suggestion: GiftSuggestion, canEdit: Bool, isPresented: Binding<Bool>, onSuggestionUpdated: @escaping (GiftSuggestion) -> Void) {
        self.suggestion = suggestion
        self.canEdit = canEdit
        self._isPresented = isPresented
        self.onSuggestionUpdated = onSuggestionUpdated
        _title = State(initialValue: suggestion.title)
        _description = State(initialValue: suggestion.description ?? "")
        _link = State(initialValue: suggestion.link ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gift Details")) {
                    TextField("Title", text: $title)
                        .textContentType(.none)
                        .disabled(!canEdit)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .textContentType(.none)
                        .disabled(!canEdit)
                    
                    TextField("Link", text: $link)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disabled(!canEdit)
                }
                
                Section(header: Text("Metadata")) {
                    Text("Suggested by: \(suggestion.suggestedBy)")
                        .font(.caption)
                    Text("Created: \(suggestion.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                    if let purchasedBy = suggestion.purchasedBy, suggestion.isPurchased {
                        Text("Purchased by: \(purchasedBy)")
                            .font(.caption)
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
                        Button(action: saveChanges) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                                Text("Save Changes")
                            }
                        }
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Gift Suggestion")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(canEdit ? "Cancel" : "Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title cannot be empty"
            return
        }
        
        isSaving = true
        errorMessage = ""
        
        var updatedSuggestion = suggestion
        updatedSuggestion.title = trimmedTitle
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSuggestion.description = trimmedDescription.isEmpty ? nil : trimmedDescription
        let trimmedLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSuggestion.link = trimmedLink.isEmpty ? nil : trimmedLink
        
        Task {
            do {
                try await FirestoreService.shared.updateGiftSuggestion(updatedSuggestion)
                await MainActor.run {
                    isSaving = false
                    onSuggestionUpdated(updatedSuggestion)
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    EditGiftSuggestionView(
        suggestion: GiftSuggestion(wishlistId: "wishlist1", title: "Coffee Mug", description: "A large ceramic mug", link: "https://example.com", suggestedBy: "user1"),
        canEdit: true,
        isPresented: .constant(true)
    ) { _ in }
}
