import SwiftUI

struct PaywallView: View {
    @Binding var currentStep: Int

    var body: some View {
        VStack {
            Text("Subscription Options")
                .font(.largeTitle)
                .padding()
        }
        .padding()
    }
}
