import SwiftUI

import FirebaseAuth
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogin = false
    @State private var showingSignUp = false
    @State private var selectedTab: DashboardTab = .events
    
    enum DashboardTab {
        case events
        case account
    }
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
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
    
    private var authenticatedView: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .events:
                    EventsListView()
                case .account:
                    AccountView()
                }
            }
            .toolbarTitleDisplayMode(.large)
        }
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selectedTab: ContentView.DashboardTab
    
    var body: some View {
        HStack(spacing: 24) {
            tabButton(
                title: "Events",
                systemImage: "calendar",
                tab: .events
            )
            
            tabButton(
                title: "Account",
                systemImage: "person.circle",
                tab: .account
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private func tabButton(title: String, systemImage: String, tab: ContentView.DashboardTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
