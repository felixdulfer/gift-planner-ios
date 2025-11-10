import Foundation
import FirebaseFirestore

struct GiftSuggestion: Identifiable, Codable {
    @DocumentID var id: String?
    var wishlistId: String
    var title: String
    var description: String?
    var link: String?
    var suggestedBy: String // User ID
    var createdAt: Date
    var isFavorited: Bool
    var isPurchased: Bool
    var purchasedBy: String? // User ID who purchased it
    var sortOrder: Int = 0
    
    init(
        id: String? = nil,
        wishlistId: String,
        title: String,
        description: String? = nil,
        link: String? = nil,
        suggestedBy: String,
        createdAt: Date = Date(),
        isFavorited: Bool = false,
        isPurchased: Bool = false,
        purchasedBy: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.wishlistId = wishlistId
        self.title = title
        self.description = description
        self.link = link
        self.suggestedBy = suggestedBy
        self.createdAt = createdAt
        self.isFavorited = isFavorited
        self.isPurchased = isPurchased
        self.purchasedBy = purchasedBy
        self.sortOrder = sortOrder
    }
}

