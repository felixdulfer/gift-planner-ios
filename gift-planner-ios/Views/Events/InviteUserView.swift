import SwiftUI

struct InviteUserView: View {
    @State private var inviteEmail = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    let eventId: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $inviteEmail)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                } header: {
                    Text("Enter the email address of the user you want to invite")
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: inviteUser) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("Invite User")
                        }
                    }
                    .disabled(isLoading || inviteEmail.isEmpty)
                }
            }
            .navigationTitle("Invite User")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func inviteUser() {
        guard !inviteEmail.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Find user by email
                guard let user = try await FirestoreService.shared.getUserByEmail(inviteEmail) else {
                    await MainActor.run {
                        errorMessage = "User not found"
                        isLoading = false
                    }
                    return
                }
                
                guard let userId = user.id else {
                    await MainActor.run {
                        errorMessage = "Invalid user"
                        isLoading = false
                    }
                    return
                }
                
                // Add user to event
                try await FirestoreService.shared.addMemberToEvent(eventId: eventId, userId: userId)
                
                await MainActor.run {
                    isLoading = false
                    inviteEmail = ""
                    isPresented = false
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
    InviteUserView(eventId: "event1", isPresented: .constant(true))
}

