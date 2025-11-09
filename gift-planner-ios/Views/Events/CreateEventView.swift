import SwiftUI

struct CreateEventView: View {
    @StateObject private var authService = AuthService()
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var hasDate = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    var onEventCreated: ((String) -> Void)?
    
    init(isPresented: Binding<Bool>, onEventCreated: ((String) -> Void)? = nil) {
        self._isPresented = isPresented
        self.onEventCreated = onEventCreated
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
                    Button(action: createEvent) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("Create Event")
                        }
                    }
                    .disabled(isLoading || eventName.isEmpty)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func createEvent() {
        guard let userId = authService.userId else {
            errorMessage = "You must be signed in to create an event"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let event = Event(
            name: eventName,
            createdBy: userId,
            eventDate: hasDate ? eventDate : nil,
            memberIds: [userId]
        )
        
        Task {
            do {
                _ = try await FirestoreService.shared.createEvent(event)
                await MainActor.run {
                    isLoading = false
                    let createdEventName = eventName
                    isPresented = false
                    // Call callback after dismissing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onEventCreated?(createdEventName)
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
    CreateEventView(isPresented: .constant(true))
}

