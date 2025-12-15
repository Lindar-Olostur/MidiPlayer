import SwiftUI

struct PWFeatureView: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(.fillPrimary)
                .frame(width: 4)
            Text(text).font(.body)
            Spacer()
        }
    }
}

#Preview {
    PWFeatureView(text: "wdncn wjdncjnwdcwd")
}
