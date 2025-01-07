import SwiftUI

struct ReminderSetupView: View {
    @Binding var currentStep: Int
    @Binding var reminderTime: Date

    var body: some View {
        VStack {
            Text("Set a daily reminder for self-reflection")
            DatePicker("Select Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .padding()
        }
        .padding()
    }
} 
