import SwiftUI
import Firebase
import FirebaseFirestore

struct Admin: View {
    @State private var maxBet: Double = 0 // To hold the current max bet value
    @State private var isLoading: Bool = true // Loading state for initial data fetch
    @State private var errorMessage: String? // To hold any error messages
    @State private var players: [Player] = [] // Array to hold player data
    @State private var totalAdminEarnings: Double = 0 // Admin's total earnings

    var body: some View {
        VStack {
            Text("Admin Dashboard")
                .font(.largeTitle)
                .padding()

            // Max bet settings
            Text("Current Maximum Bet: \(Int(maxBet))")
                .padding()

            Slider(value: $maxBet, in: 0...10, step: 1) // Adjust range as needed
                .padding()

            TextField("Set Maximum Bet", value: $maxBet, formatter: NumberFormatter())
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 300)

            Button(action: saveMaxBet) {
                Text("Save Maximum Bet")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()

            // Display player winnings list
            if isLoading {
                ProgressView() // Show while data is loading
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                // Display player names and winnings
                // Display player names and winnings
                List {
                    ForEach(players) { player in
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(player.username)
                                        .font(.headline)
                                    Text("Winnings: \(String(format: "%.2f", player.winnings))")
                                        .foregroundColor(player.winnings >= 0 ? .green : .red)
                                        .font(.body)
                                }
                                
                                Spacer()
                            }
                            .padding()

                            // Label for editing winnings
                            Text("Edit Player Winnings")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            // Text field to change player winnings
                            TextField("Change Winnings", value: Binding(
                                get: { player.changeAmount },
                                set: { newValue in
                                    updatePlayerWinnings(player: player, newValue: newValue)
                                }
                            ), formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 120)
                            .padding(.bottom)
                        }
                        .padding()
                    }
                }

            }

            // Admin's total earnings at the bottom
            Text("Admin's Total Earnings: \(String(format: "%.2f", totalAdminEarnings))")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(totalAdminEarnings >= 0 ? .green : .red)
                .padding()
        }
        .onAppear {
            fetchMaxBet() // Fetch max bet and player data when view appears
            fetchPlayers()
        }
    }

    // Function to fetch the current max bet setting
    private func fetchMaxBet() {
        let db = Firestore.firestore()
        db.collection("max bet").document("config")
            .getDocument { (document, error) in
                if let error = error {
                    errorMessage = "Error fetching max bet: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                
                if let document = document, document.exists {
                    if let max = document.get("max") as? Double {
                        maxBet = max
                    } else {
                        errorMessage = "Invalid data format."
                    }
                } else {
                    errorMessage = "Document does not exist."
                }
                isLoading = false
            }
    }

    // Function to save the max bet setting
    private func saveMaxBet() {
        let db = Firestore.firestore()
        db.collection("max bet").document("config")
            .setData(["max": maxBet], merge: true) { error in
                if let error = error {
                    errorMessage = "Error updating max bet: \(error.localizedDescription)"
                } else {
                    errorMessage = "Max bet updated successfully!"
                }
            }
    }

    // Function to fetch player data
    private func fetchPlayers() {
        let db = Firestore.firestore()
        db.collection("winnings").getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error fetching players: \(error.localizedDescription)"
                return
            }

            guard let documents = snapshot?.documents else {
                errorMessage = "No players found."
                return
            }

            // Map Firestore data to Player structs
            players = documents.compactMap { document in
                let data = document.data()
                let username = document.documentID
                let winnings = data["amount"] as? Double ?? 0
                return Player(username: username, winnings: winnings, changeAmount: 0)
            }

            // Calculate admin's total earnings (negative sum of all player winnings)
            totalAdminEarnings = -(players.reduce(0) { $0 + $1.winnings })
        }
    }

    // Function to update player's winnings
    private func updatePlayerWinnings(player: Player, newValue: Double) {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else { return }

        // Update winnings locally
        let db = Firestore.firestore()
        let newWinnings = player.winnings + newValue
        db.collection("winnings").document(player.username).setData(["amount": newWinnings]) { error in
            if let error = error {
                errorMessage = "Error updating winnings: \(error.localizedDescription)"
            } else {
                players[index].winnings = newWinnings
                players[index].changeAmount = 0 // Reset change amount after updating

                // Recalculate admin's total earnings
                totalAdminEarnings = -(players.reduce(0) { $0 + $1.winnings })
            }
        }
    }
}

// Player model struct
struct Player: Identifiable {
    let id = UUID()
    let username: String
    var winnings: Double
    var changeAmount: Double // To hold any temporary changes to winnings
}

struct Admin_Previews: PreviewProvider {
    static var previews: some View {
        Admin()
    }
}
