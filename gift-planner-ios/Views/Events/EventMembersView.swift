import SwiftUI

struct EventMembersView: View {
    let event: Event
    @State private var members: [AppUser] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Members (\(members.count))")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if members.isEmpty {
                    Text("No members found")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(members) { member in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.displayName)
                                    .font(.headline)
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if member.id == event.createdBy {
                                Text("Creator")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Event Members")
        .task {
            await loadMembers()
        }
    }
    
    private func loadMembers() async {
        isLoading = true
        errorMessage = ""
        
        var loadedMembers: [AppUser] = []
        
        // Load each member's details
        for memberId in event.memberIds {
            do {
                let user = try await FirestoreService.shared.getUser(userId: memberId)
                loadedMembers.append(user)
            } catch {
                print("Error loading user \(memberId): \(error)")
                // Continue loading other members even if one fails
            }
        }
        
        await MainActor.run {
            self.members = loadedMembers
            self.isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        EventMembersView(
            event: Event(name: "Christmas 2025", createdBy: "user1", memberIds: ["user1", "user2"])
        )
    }
}

