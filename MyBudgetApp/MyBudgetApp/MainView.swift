import SwiftUI

struct MainView: View {
    // User's current balance
    @State private var balance: Double = UserDefaults.standard.double(forKey: "balance") // Load balance from UserDefaults
    
    @State private var isIncomeViewPresented = false // Control the presentation of IncomeView
    @State private var isExpenseViewPresented = false // Control the presentation of ExpenseView
    
    // Colors to display
    let colors: [Color] = [.red, .green, .blue, .orange, .purple] // Replace with your desired colors
    
    // Index to track the currently displayed color
    @State private var currentColorIndex: Int = 0
    
    init() {
        print("Initial balance loaded:", balance)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(String(format: "%.2f €", balance)) // Display the balance with currency
                    .font(.largeTitle)
                    .padding()
                
                // Color Display
                ZStack{
                    Circle()
                        .fill(colors[currentColorIndex])
                        .frame(width: 200, height: 200) // Use a fixed size circle
                        .transition(.scale)
                        .animation(.easeInOut(duration: 0.3))
                    
                    // Navigation Buttons
                    HStack(spacing: 175) {
                        // Previous Button
                        Button(action: { showPreviousColor() }) {
                            Image(systemName: "lessthan.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.primary)
                        }
                        .padding()
                        
                        // Next Button
                        Button(action: { showNextColor() }) {
                            Image(systemName: "greaterthan.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                }
                
                
                Spacer()
                
                HStack(spacing: 100) {
                    // Expense View Button
                    Button(action: { isExpenseViewPresented = true }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .frame(width: 60, height: 60)
                            .background(Circle().foregroundColor(.white))
                    }
                    .padding()
                    
                    // Income View Button
                    Button(action: { isIncomeViewPresented = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .frame(width: 60, height: 60)
                            .background(Circle().foregroundColor(.white))
                    }
                    .padding()
                }
                .sheet(isPresented: $isIncomeViewPresented) {
                    // Pass the balance and isPresented bindings to IncomeView
                    IncomeView(mainViewBalance: $balance, isPresented: $isIncomeViewPresented)
                }
                .sheet(isPresented: $isExpenseViewPresented) {
                    // Pass the balance and isPresented bindings to ExpenseView
                    ExpenseView(mainViewBalance: $balance, isPresented: $isExpenseViewPresented)
                }
            }
            .navigationBarTitle("MyBudget", displayMode: .large)
        }
    }
    
    // Update the balance in UserDefaults when it changes
    private var balanceBinding: Binding<Double> {
        Binding<Double>(
            get: { self.balance },
            set: { newValue in
                self.balance = newValue
                UserDefaults.standard.set(newValue, forKey: "balance")
                UserDefaults.standard.synchronize() // Force immediate synchronization
            }
        )
    }
    
    private func showNextColor() {
            if currentColorIndex < colors.count - 1 {
                currentColorIndex += 1
            } else {
                currentColorIndex = 0 // Wrap to the first color
            }
        }
        
        private func showPreviousColor() {
            if currentColorIndex > 0 {
                currentColorIndex -= 1
            } else {
                currentColorIndex = colors.count - 1 // Wrap to the last color
            }
        }
}

#Preview {
    MainView()
}
