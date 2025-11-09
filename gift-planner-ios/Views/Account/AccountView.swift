import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authService: AuthService
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.displayName ?? "Unnamed User")
                                .font(.headline)
                            if let email = authService.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button(role: .destructive) {
                        do {
                            try authService.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Label("Sign Out", systemImage: "arrowshape.turn.up.left")
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthService())
}
