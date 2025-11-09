import Foundation
import FirebaseFirestore
import Combine

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - User Operations
    
    func createUser(_ user: AppUser) async throws {
        guard let id = user.id else { throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is required"]) }
        try db.collection("users").document(id).setData(from: user)
    }
    
    func getUser(userId: String) async throws -> AppUser {
        let document = try await db.collection("users").document(userId).getDocument()
        return try document.data(as: AppUser.self)
    }
    
    func getUserByEmail(_ email: String) async throws -> AppUser? {
        let snapshot = try await db.collection("users").whereField("email", isEqualTo: email).limit(to: 1).getDocuments()
        return snapshot.documents.first.flatMap { try? $0.data(as: AppUser.self) }
    }
    
    // MARK: - Event Operations
    
    func createEvent(_ event: Event) async throws -> String {
        let ref = try db.collection("events").addDocument(from: event)
        return ref.documentID
    }
    
    func getEvents(for userId: String) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Event.self) }
    }
    
    func getEvent(eventId: String) async throws -> Event {
        let document = try await db.collection("events").document(eventId).getDocument()
        guard let event = try? document.data(as: Event.self) else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        return event
    }
    
    func updateEvent(_ event: Event) async throws {
        guard let id = event.id else { throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Event ID is required"]) }
        try db.collection("events").document(id).setData(from: event, merge: true)
    }
    
    func deleteEvent(eventId: String) async throws {
        try await db.collection("events").document(eventId).delete()
    }
    
    func addMemberToEvent(eventId: String, userId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        try await eventRef.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }
    
    // MARK: - Wishlist Operations
    
    func createWishlist(_ wishlist: Wishlist) async throws -> String {
        let ref = try db.collection("wishlists").addDocument(from: wishlist)
        return ref.documentID
    }
    
    func getWishlists(for eventId: String) async throws -> [Wishlist] {
        let snapshot = try await db.collection("wishlists")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Wishlist.self) }
    }
    
    func getWishlist(wishlistId: String) async throws -> Wishlist {
        let document = try await db.collection("wishlists").document(wishlistId).getDocument()
        guard let wishlist = try? document.data(as: Wishlist.self) else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wishlist not found"])
        }
        return wishlist
    }
    
    func updateWishlist(_ wishlist: Wishlist) async throws {
        guard let id = wishlist.id else { throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wishlist ID is required"]) }
        try db.collection("wishlists").document(id).setData(from: wishlist, merge: true)
    }
    
    func deleteWishlist(wishlistId: String) async throws {
        // Also delete all gift suggestions for this wishlist
        let suggestionsSnapshot = try await db.collection("giftSuggestions")
            .whereField("wishlistId", isEqualTo: wishlistId)
            .getDocuments()
        
        for document in suggestionsSnapshot.documents {
            try await document.reference.delete()
        }
        
        try await db.collection("wishlists").document(wishlistId).delete()
    }
    
    // MARK: - Gift Suggestion Operations
    
    func createGiftSuggestion(_ suggestion: GiftSuggestion) async throws -> String {
        print("FirestoreService: Creating gift suggestion: \(suggestion.title) for wishlist: \(suggestion.wishlistId)")
        let ref = try db.collection("giftSuggestions").addDocument(from: suggestion)
        print("FirestoreService: Created gift suggestion with ID: \(ref.documentID)")
        return ref.documentID
    }
    
    func getGiftSuggestions(for wishlistId: String) async throws -> [GiftSuggestion] {
        print("FirestoreService: Querying giftSuggestions for wishlistId: \(wishlistId)")
        let snapshot = try await db.collection("giftSuggestions")
            .whereField("wishlistId", isEqualTo: wishlistId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        print("FirestoreService: Found \(snapshot.documents.count) documents")
        
        let suggestions = snapshot.documents.compactMap { doc -> GiftSuggestion? in
            do {
                let suggestion = try doc.data(as: GiftSuggestion.self)
                print("FirestoreService: Successfully decoded suggestion: \(suggestion.title)")
                return suggestion
            } catch {
                print("FirestoreService: Error decoding document \(doc.documentID): \(error)")
                return nil
            }
        }
        
        print("FirestoreService: Returning \(suggestions.count) gift suggestions")
        return suggestions
    }
    
    func updateGiftSuggestion(_ suggestion: GiftSuggestion) async throws {
        guard let id = suggestion.id else { throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gift suggestion ID is required"]) }
        try db.collection("giftSuggestions").document(id).setData(from: suggestion, merge: true)
    }
    
    func deleteGiftSuggestion(suggestionId: String) async throws {
        try await db.collection("giftSuggestions").document(suggestionId).delete()
    }
    
    func toggleFavorite(suggestionId: String, isFavorited: Bool) async throws {
        try await db.collection("giftSuggestions").document(suggestionId).updateData([
            "isFavorited": isFavorited
        ])
    }
    
    func markAsPurchased(suggestionId: String, purchasedBy: String) async throws {
        try await db.collection("giftSuggestions").document(suggestionId).updateData([
            "isPurchased": true,
            "purchasedBy": purchasedBy
        ])
    }
    
    func markAsNotPurchased(suggestionId: String) async throws {
        try await db.collection("giftSuggestions").document(suggestionId).updateData([
            "isPurchased": false,
            "purchasedBy": FieldValue.delete()
        ])
    }
}

