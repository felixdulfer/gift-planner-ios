import Foundation
import FirebaseFirestore

struct Wishlist: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var name: String
    var createdBy: String // User ID
    var createdAt: Date
    
    init(id: String? = nil, eventId: String, name: String, createdBy: String, createdAt: Date = Date()) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

