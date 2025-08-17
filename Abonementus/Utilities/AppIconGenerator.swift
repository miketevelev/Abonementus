import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.blue.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon elements
            VStack(spacing: 8) {
                // Calendar/Subscription representation
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 60, height: 40)
                    .overlay(
                        VStack(spacing: 2) {
                            // Calendar header
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            // Calendar content
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.blue.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    )
                
                // Lesson/Checkmark representation
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < 2 ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Group {
                                    if index < 2 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                }
            }
        }
        .frame(width: 512, height: 512)
        .clipShape(RoundedRectangle(cornerRadius: 100))
    }
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
            .frame(width: 200, height: 200)
            .previewLayout(.sizeThatFits)
    }
}
