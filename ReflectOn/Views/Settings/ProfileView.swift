import SwiftUI

struct ProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var showingEditSheet = false
    @State private var editingField: ProfileField?
    @State private var editValue: String = ""
    
    enum ProfileField: String {
        case age = "age"
        case gender = "gender"
        case reminderTime = "reminderTime"
    }
    
    var body: some View {
        List {
            if let user = userViewModel.user {
                Section(header: Text("Personal Information")) {
                    if !user.email.isEmpty {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        editingField = .age
                        editValue = String(user.age)
                        showingEditSheet = true
                    }) {
                        HStack {
                            Label("Age", systemImage: "person")
                            Spacer()
                            Text("\(user.age)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        editingField = .gender
                        editValue = user.gender
                        showingEditSheet = true
                    }) {
                        HStack {
                            Label("Gender", systemImage: "person.2")
                            Spacer()
                            Text(user.gender)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Button(action: {
                        editingField = .reminderTime
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        editValue = formatter.string(from: user.reminderTime)
                        showingEditSheet = true
                    }) {
                        HStack {
                            Label("Daily Reminder", systemImage: "bell")
                            Spacer()
                            let formatter = DateFormatter()
                            Text(formatter.string(from: user.reminderTime))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Focus Areas")) {
                    ForEach(user.focusAreas, id: \.self) { area in
                        Label(area, systemImage: "target")
                            .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Subscription")) {
                    HStack {
                        Label("Status", systemImage: "creditcard")
                        Spacer()
                        Text(user.subscriptionStatus.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
            } else if userViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                EditProfileView(field: editingField ?? .age,
                              value: $editValue,
                              onSave: saveField)
            }
        }
        .refreshable {
            userViewModel.fetchUserData()
        }
        .onAppear {
            userViewModel.fetchUserData()
        }
        .alert("Error", isPresented: Binding(
            get: { userViewModel.error != nil },
            set: { if !$0 { userViewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = userViewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func saveField() {
        guard let field = editingField else { return }
        
        switch field {
        case .age:
            if let age = Int(editValue) {
                userViewModel.updateUserData(field: "age", value: age)
            }
        case .gender:
            userViewModel.updateUserData(field: "gender", value: editValue)
        case .reminderTime:
            userViewModel.updateUserData(field: "reminderTime", value: editValue)
        }
        
        showingEditSheet = false
    }
}

struct EditProfileView: View {
    let field: ProfileView.ProfileField
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    var body: some View {
        Form {
            switch field {
            case .age:
                TextField("Age", text: $value)
                    .keyboardType(.numberPad)
            case .gender:
                TextField("Gender", text: $value)
            case .reminderTime:
                DatePicker(
                    "Select Time",
                    selection: Binding(
                        get: {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            return formatter.date(from: value) ?? Date()
                        },
                        set: { newDate in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            value = formatter.string(from: newDate)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
        .navigationTitle("Edit \(field.rawValue.capitalized)")
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            },
            trailing: Button("Save") {
                onSave()
                dismiss()
            }
        )
    }
} 
