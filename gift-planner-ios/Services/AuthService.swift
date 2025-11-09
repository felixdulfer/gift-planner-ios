import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    var userId: String? {
        currentUser?.uid
    }
    
    var displayName: String? {
        currentUser?.displayName
    }

    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Set initial state from cached user (if available) immediately
        // This allows UI to render immediately without waiting for network auth check
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
        }
        
        // Add auth state listener - this is non-blocking and will update
        // state asynchronously when network check completes
        self.handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // Create user document in Firestore
        let user = AppUser(
            id: result.user.uid,
            email: email,
            displayName: displayName
        )
        try await FirestoreService.shared.createUser(user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}

