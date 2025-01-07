import SwiftUI
import Firebase
import GoogleSignIn

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LoginViewModel
    @State private var showWelcomePage = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileView()
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.signOut()
                            showWelcomePage = true
                        }
                    }) {
                        HStack {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .fullScreenCover(isPresented: $showWelcomePage) {
                WelcomePageView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
} 