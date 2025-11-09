import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let message = message {
                        ToastView(message: message)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message)
                    }
                }
                .zIndex(1000)
            )
            .onChange(of: message) { oldValue, newValue in
                if newValue != nil {
                    showToast()
                }
            }
    }
    
    private func showToast() {
        workItem?.cancel()
        
        let task = DispatchWorkItem {
            withAnimation {
                message = nil
            }
        }
        
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.8))
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

