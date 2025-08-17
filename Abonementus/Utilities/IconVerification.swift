import SwiftUI

struct IconVerificationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Verification")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Required Icon Sizes:")
                    .font(.headline)
                
                Group {
                    Text("• 16x16 (1x) - Icon-16.png")
                    Text("• 16x16 (2x) - Icon-32.png")
                    Text("• 32x32 (1x) - Icon-32.png")
                    Text("• 32x32 (2x) - Icon-64.png")
                    Text("• 128x128 (1x) - Icon-128.png")
                    Text("• 128x128 (2x) - Icon-256.png")
                    Text("• 256x256 (1x) - Icon-256.png")
                    Text("• 256x256 (2x) - Icon-512.png")
                    Text("• 512x512 (1x) - Icon-512.png")
                    Text("• 512x512 (2x) - Icon-1024.png")
                }
                .font(.system(.body, design: .monospaced))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Troubleshooting Steps:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Clean build folder (Cmd+Shift+K)")
                Text("2. Clean build (Cmd+K)")
                Text("3. Restart Xcode")
                Text("4. Rebuild project")
                Text("5. Check that all icon files are in Assets.xcassets/AppIcon.appiconset/")
            }
            .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct IconVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        IconVerificationView()
    }
}
