import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Playing: View {
    @State private var username: String = ""
    @State private var showAdminPasswordAlert = false
    @State private var adminPassword = ""
    @State private var isAdminAuthenticated = false
    @State private var betAmount: Double = 0
    @State private var winnings: Double = 0
    @State private var multiplier: Int = 1
    private let db = Firestore.firestore()
    
    @State private var selectedMultiplier: Int = 1
    @State private var showMultiplierOptions = false

    @State private var maxBet: Double = 2

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome, \(username)!")
                    .font(.largeTitle)
                    .padding()

                Text("Your Winnings: $\(String(format: "%.2f", winnings))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(winnings >= 0 ? .green : .red)
                    .padding()

                VStack {
                    Text("Bet Amount:")
                        .font(.headline)

                    ZStack {
                        Slider(value: $betAmount, in: 0...maxBet, step: 0.01) {
                            Text("Bet Amount: \(String(format: "%.2f", betAmount))")
                        }
                        .padding()

                        Text(String(format: "%.2f", betAmount))
                            .font(.title)
                            .bold()
                            .padding(.top, -50)
                            .foregroundColor(.black)
                    }

                    TextField("Enter Bet Amount", value: $betAmount, formatter: NumberFormatter()) {
                        if betAmount > maxBet {
                            betAmount = maxBet
                        }
                    }
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(height: 70)
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                .padding()

                HStack(spacing: 20) {
                    Button(action: {
                        updateWinnings(isWin: true, multiplier: selectedMultiplier)
                        alertTitle = "Congratulations!"
                        alertMessage = "You won $\(String(format: "%.2f", betAmount * Double(multiplier)))"
                        showAlert = true
                    }) {
                        Text("Win")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 100, height: 60)
                            .background(Color.green)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .onTapGesture {
                        showMultiplierOptions.toggle()
                    }

                    if showMultiplierOptions {
                        Picker("Multiplier", selection: $selectedMultiplier) {
                            Text("1x").tag(1)
                            Text("2x").tag(2)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                    }

                    Button(action: {
                        updateWinnings(isWin: false, multiplier: selectedMultiplier)
                        alertTitle = "Oh no!"
                        alertMessage = "You lost $\(String(format: "%.2f", betAmount * Double(multiplier)))"
                        showAlert = true
                    }) {
                        Text("Lose")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 100, height: 60)
                            .background(Color.red)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .onTapGesture {
                        showMultiplierOptions.toggle()
                    }

                    if showMultiplierOptions {
                        Picker("Multiplier", selection: $selectedMultiplier) {
                            Text("1x").tag(1)
                            Text("2x").tag(2)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                    }
                }
                .padding()

                NavigationLink(destination: Admin(), isActive: $isAdminAuthenticated) {
                    EmptyView()
                }
                .hidden()
            }
            .onAppear {
                fetchUserData()
                fetchMaxBet()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Player") {}
                        Button("Admin") {
                            showAdminPasswordAlert.toggle()
                        }
                    } label: {
                        Label("Menu", systemImage: "line.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showAdminPasswordAlert) {
                AdminPasswordEntryView(adminPassword: $adminPassword, isAuthenticated: $isAdminAuthenticated)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func fetchUserData() {
        if let user = Auth.auth().currentUser {
            username = user.email?.components(separatedBy: "@").first ?? "User"
            fetchWinnings(for: username)
        }
    }

    private func fetchWinnings(for username: String) {
        db.collection("winnings").document(username).getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(), let currentWinnings = data["amount"] as? Double {
                    winnings = currentWinnings
                }
            } else {
                winnings = 0
                db.collection("winnings").document(username).setData(["amount": winnings])
            }
        }
    }

    private func fetchMaxBet() {
        db.collection("maxBet").document("betLimits").getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(), let fetchedMaxBet = data["max"] as? Double {
                    maxBet = fetchedMaxBet
                }
            }
        }
    }

    private func updateWinnings(isWin: Bool, multiplier: Int) {
        let betValue = betAmount
        let changeAmount = isWin ? betValue * Double(multiplier) : -betValue * Double(multiplier)
        winnings += changeAmount

        db.collection("winnings").document(username).setData(["amount": winnings]) { error in
            if let error = error {
                print("Error updating winnings: \(error)")
            } else {
                print("Winnings updated successfully!")
            }
        }
    }
}

struct AdminPasswordEntryView: View {
    @Binding var adminPassword: String
    @Binding var isAuthenticated: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    let correctPassword = "4361"

    var body: some View {
        VStack {
            Text("Enter Admin Password")
                .font(.headline)
                .padding()
            
            SecureField("Password", text: $adminPassword)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)

            Button(action: {
                if adminPassword == correctPassword {
                    isAuthenticated = true
                    presentationMode.wrappedValue.dismiss()
                } else {
                    isAuthenticated = false
                }
            }) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
