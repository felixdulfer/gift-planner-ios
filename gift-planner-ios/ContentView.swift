import SwiftUI

import FirebaseAuth
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogin = false
    @State private var showingSignUp = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                EventsListView()
                    .environmentObject(authService)
            } else {
                VStack(spacing: 30) {
                    Image(systemName: "gift.fill")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .font(.system(size: 60))
                    
                    Text("Gift Planner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Plan and organize gifts for your events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        Button(action: { showingLogin = true }) {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button(action: { showingSignUp = true }) {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
                .sheet(isPresented: $showingLogin) {
                    LoginView(isPresented: $showingLogin)
                        .environmentObject(authService)
                }
                .sheet(isPresented: $showingSignUp) {
                    SignUpView(isPresented: $showingSignUp)
                        .environmentObject(authService)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
