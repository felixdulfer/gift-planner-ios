import SwiftUI

struct EventDetailView: View {
    @StateObject private var authService = AuthService()
    @Environment(\.dismiss) private var dismiss
    let event: Event
    let onEventDeleted: ((String) -> Void)?
    @State private var wishlists: [Wishlist] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingCreateWishlist = false
    @State private var showingInviteUser = false
    
    init(event: Event, onEventDeleted: ((String) -> Void)? = nil) {
        self.event = event
        self.onEventDeleted = onEventDeleted
    }
    
    var canEdit: Bool {
        guard let userId = authService.userId else { return false }
        return event.memberIds.contains(userId)
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let eventDate = event.eventDate {
                        HStack {
                            Image(systemName: "calendar")
                            Text(eventDate, style: .date)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "person.2")
                        Text("\(event.memberIds.count) member\(event.memberIds.count == 1 ? "" : "s")")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            if canEdit {
                Section {
                    Button(action: { showingInviteUser = true }) {
                        Label("Invite User", systemImage: "person.badge.plus")
                    }
                }
            }
            
            Section(header: Text("Wishlists")) {
                if wishlists.isEmpty {
                    Text("No wishlists yet")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(wishlists) { wishlist in
                        NavigationLink(destination: WishlistDetailView(wishlist: wishlist, event: event)) {
                            Text(wishlist.name)
                        }
                    }
                    .onDelete(perform: deleteWishlists)
                }
            }
            
            if canEdit {
                Section {
                    Button(action: { showingCreateWishlist = true }) {
                        Label("Create Wishlist", systemImage: "plus.circle")
                    }
                }
            }
        }
        .navigationTitle("Event Details")
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            Task {
                                await deleteEvent()
                            }
                        }) {
                            Label("Delete Event", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateWishlist) {
            CreateWishlistView(eventId: event.id ?? "", isPresented: $showingCreateWishlist)
        }
        .onChange(of: showingCreateWishlist) { oldValue, newValue in
            // Reload wishlists when sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    await loadWishlists()
                }
            }
        }
        .sheet(isPresented: $showingInviteUser) {
            if let eventId = event.id {
                InviteUserView(eventId: eventId, isPresented: $showingInviteUser)
            }
        }
        .task {
            await loadWishlists()
        }
        .refreshable {
            await loadWishlists()
        }
    }
    
    private func loadWishlists() async {
        guard let eventId = event.id else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let loadedWishlists = try await FirestoreService.shared.getWishlists(for: eventId)
            await MainActor.run {
                self.wishlists = loadedWishlists
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func deleteWishlists(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let wishlist = wishlists[index]
                guard let wishlistId = wishlist.id else { continue }
                
                do {
                    try await FirestoreService.shared.deleteWishlist(wishlistId: wishlistId)
                    await loadWishlists()
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func deleteEvent() async {
        guard let eventId = event.id else { return }
        let eventName = event.name
        
        do {
            try await FirestoreService.shared.deleteEvent(eventId: eventId)
            await MainActor.run {
                // Call the callback before dismissing
                onEventDeleted?(eventName)
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationView {
        EventDetailView(event: Event(name: "Christmas 2025", createdBy: "user1", memberIds: ["user1"]))
    }
}

