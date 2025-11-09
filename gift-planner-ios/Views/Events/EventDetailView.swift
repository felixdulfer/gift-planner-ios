import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    let onEventDeleted: ((String) -> Void)?
    @State private var currentEvent: Event
    @State private var wishlists: [Wishlist] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingCreateWishlist = false
    @State private var showingInviteUser = false
    @State private var showingEditEvent = false
    @State private var showingMembers = false
    @State private var toastMessage: String?
    
    init(event: Event, onEventDeleted: ((String) -> Void)? = nil) {
        self.onEventDeleted = onEventDeleted
        self._currentEvent = State(initialValue: event)
    }
    
    var canEdit: Bool {
        guard let userId = authService.userId else { return false }
        return currentEvent.memberIds.contains(userId)
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentEvent.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let eventDate = currentEvent.eventDate {
                        HStack {
                            Image(systemName: "calendar")
                            Text(eventDate, style: .date)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingMembers = true }) {
                        HStack {
                            Image(systemName: "person.2")
                            Text("\(currentEvent.memberIds.count) member\(currentEvent.memberIds.count == 1 ? "" : "s")")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
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
                        NavigationLink(destination: WishlistDetailView(wishlist: wishlist, event: currentEvent)
                            .environmentObject(authService)) {
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
                        Button(action: { showingEditEvent = true }) {
                            Label("Edit Event", systemImage: "pencil")
                        }
                        
                        Button(action: { showingMembers = true }) {
                            Label("View Members", systemImage: "person.2")
                        }
                        
                        Divider()
                        
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
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMembers = true }) {
                        Image(systemName: "person.2")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateWishlist) {
            CreateWishlistView(
                eventId: currentEvent.id ?? "",
                isPresented: $showingCreateWishlist,
                onWishlistCreated: { wishlistName in
                    toastMessage = "Wishlist \"\(wishlistName)\" created"
                    Task {
                        await loadWishlists()
                    }
                }
            )
            .environmentObject(authService)
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
            if let eventId = currentEvent.id {
                InviteUserView(
                    eventId: eventId,
                    isPresented: $showingInviteUser,
                    onUserInvited: {
                        Task {
                            await loadEvent()
                            await loadWishlists()
                        }
                    }
                )
                .environmentObject(authService)
            }
        }
        .sheet(isPresented: $showingEditEvent) {
            EditEventView(
                event: currentEvent,
                isPresented: $showingEditEvent,
                onEventUpdated: {
                    toastMessage = "Event updated"
                    Task {
                        await loadEvent()
                        await loadWishlists()
                    }
                }
            )
        }
        .sheet(isPresented: $showingMembers) {
            NavigationView {
                EventMembersView(event: currentEvent)
                    .environmentObject(authService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingMembers = false
                            }
                        }
                    }
            }
        }
        .task {
            await loadWishlists()
        }
        .refreshable {
            await loadWishlists()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 80)
        }
        .toast(message: $toastMessage)
    }
    
    private func loadWishlists() async {
        guard let eventId = currentEvent.id else { return }
        
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
    
    private func loadEvent() async {
        guard let eventId = currentEvent.id else { return }
        
        do {
            let updatedEvent = try await FirestoreService.shared.getEvent(eventId: eventId)
            await MainActor.run {
                self.currentEvent = updatedEvent
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
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
        guard let eventId = currentEvent.id else { return }
        let eventName = currentEvent.name
        
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
            .environmentObject(AuthService())
    }
}

