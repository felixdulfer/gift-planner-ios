import SwiftUI

struct EventsListView: View {
    @StateObject private var authService = AuthService()
    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingCreateEvent = false
    @State private var showingInviteUser = false
    @State private var selectedEvent: Event?
    @State private var toastMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading events...")
                } else if events.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No events yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Create your first event to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Create Event") {
                            showingCreateEvent = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(events) { event in
                            NavigationLink(destination: EventDetailView(
                                event: event,
                                onEventDeleted: { eventName in
                                    toastMessage = "Event \"\(eventName)\" deleted"
                                    Task {
                                        await loadEvents()
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.name)
                                        .font(.headline)
                                    if let eventDate = event.eventDate {
                                        Text(eventDate, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(event.memberIds.count) member\(event.memberIds.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteEvents)
                    }
                }
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        try? authService.signOut()
                    }
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(isPresented: $showingCreateEvent)
            }
            .task {
                await loadEvents()
            }
            .refreshable {
                await loadEvents()
            }
            .toast(message: $toastMessage)
        }
    }
    
    private func loadEvents() async {
        guard let userId = authService.userId else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let loadedEvents = try await FirestoreService.shared.getEvents(for: userId)
            await MainActor.run {
                self.events = loadedEvents
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func deleteEvents(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let event = events[index]
                guard let eventId = event.id else { continue }
                
                do {
                    try await FirestoreService.shared.deleteEvent(eventId: eventId)
                    await loadEvents()
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

#Preview {
    EventsListView()
}

