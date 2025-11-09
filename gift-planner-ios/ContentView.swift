import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "gift.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Gift Planner")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

