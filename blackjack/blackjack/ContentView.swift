import SwiftUI
import FirebaseAuth

struct ContentView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var userIsLoggedIn = false
    @State private var wrongPassword = 0
    @State private var showRegisterAlert = false
    @State private var registerSuccess = false
    @State private var showLoginAlert = false
    @State private var loginSuccess = false
    
    var body: some View {
        if loginSuccess {
            Playing()
        } else {
            content
        }
    }
    
    var content: some View {
        ZStack {
            Color.green
                .ignoresSafeArea()
            Circle()
                .scale(1.7)
                .foregroundColor(.white.opacity(0.15))
            Circle()
                .scale(1.35)
                .foregroundColor(.white)
            
            VStack {
                Text("BLACKJACK")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                TextField("Enter Your Email", text: $email)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                
                SecureField("Enter Your Password", text: $password)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                    .border(.red, width: CGFloat(wrongPassword))
                
                Button("Sign Up") {
                    register() // Call register when the button is tapped
                }
                .foregroundColor(.white)
                .frame(width: 300, height: 50)
                .background(Color.blue)
                .cornerRadius(10)
                
                Button {
                    login()
                } label: {
                    Text("Already have an account? Login")
                        .foregroundColor(.blue)
                }
                .alert(isPresented: $showLoginAlert) {
                    Alert(title: Text(loginSuccess ? "Success" : "Error"),
                          message: Text(loginSuccess ? "Login Success" : "Invalid credentials"),
                          dismissButton: .default(Text("OK")) {
                              if loginSuccess {
                                  loginSuccess = true // Navigate to the Playing view
                              }
                          })
                }
                
                // Alert for registration success or failure
                .alert(isPresented: $showRegisterAlert) {
                    Alert(title: Text(registerSuccess ? "Success" : "Error"),
                          message: Text(registerSuccess ? "Registration Successful" : "Failed to register. Email may already be in use."),
                          dismissButton: .default(Text("OK")))
                }
                
                NavigationLink(destination: Playing(), isActive: $loginSuccess) {
                    EmptyView() // Triggers navigation when loginSuccess is true
                }
                .hidden() // Optionally hide this link from the UI
                
                .onAppear {
                    Auth.auth().addStateDidChangeListener { auth, user in
                        userIsLoggedIn = user != nil
                    }
                }
            }
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                loginSuccess = false // Indicate login failed
            } else {
                loginSuccess = true // Indicate login successful
            }
            showLoginAlert = true // Show the alert after attempting to log in
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                if let errorCode = AuthErrorCode(rawValue: error.code) {
                    switch errorCode {
                    case .emailAlreadyInUse:
                        print("Email already in use.")
                        registerSuccess = false
                    default:
                        print("Error: \(error.localizedDescription)")
                        registerSuccess = false
                    }
                }
            } else {
                registerSuccess = true // Registration successful
            }
            showRegisterAlert = true // Show the alert after attempting to register
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
