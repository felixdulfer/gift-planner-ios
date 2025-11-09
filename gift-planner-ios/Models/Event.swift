import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var createdBy: String // User ID
    var createdAt: Date
    var eventDate: Date?
    var memberIds: [String] // User IDs of all members
    
    init(id: String? = nil, name: String, createdBy: String, createdAt: Date = Date(), eventDate: Date? = nil, memberIds: [String] = []) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.eventDate = eventDate
        self.memberIds = memberIds
    }
}

