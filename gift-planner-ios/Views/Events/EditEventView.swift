import SwiftUI

struct EditEventView: View {
    @StateObject private var authService = AuthService()
    let event: Event
    @State private var eventName: String
    @State private var eventDate: Date
    @State private var hasDate: Bool
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    var onEventUpdated: (() -> Void)?
    
    init(event: Event, isPresented: Binding<Bool>, onEventUpdated: (() -> Void)? = nil) {
        self.event = event
        self._isPresented = isPresented
        self.onEventUpdated = onEventUpdated
        self._eventName = State(initialValue: event.name)
        self._eventDate = State(initialValue: event.eventDate ?? Date())
        self._hasDate = State(initialValue: event.eventDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Name", text: $eventName)
                        .textContentType(.none)
                    
                    Toggle("Set Event Date", isOn: $hasDate)
                    
                    if hasDate {
                        DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: updateEvent) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("Save Changes")
                        }
                    }
                    .disabled(isLoading || eventName.isEmpty)
                }
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func updateEvent() {
        guard let eventId = event.id else {
            errorMessage = "Event ID is missing"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        var updatedEvent = event
        updatedEvent.name = eventName
        updatedEvent.eventDate = hasDate ? eventDate : nil
        
        Task {
            do {
                try await FirestoreService.shared.updateEvent(updatedEvent)
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onEventUpdated?()
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
    EditEventView(
        event: Event(name: "Christmas 2025", createdBy: "user1", memberIds: ["user1"]),
        isPresented: .constant(true)
    )
}

