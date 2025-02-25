import SwiftUI

struct OverlayView: View {
    @Binding var analysisResult: String

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("解析結果：\(analysisResult)")
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                Spacer()
            }
            .padding()
        }
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView(analysisResult: .constant("Sample Result"))
    }
}

