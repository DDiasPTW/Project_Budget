import SwiftUI

struct MainView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    @EnvironmentObject var expenseManager: ExpenseManager
    
    // User's current balance
    @State private var balance: Double = UserDefaults.standard.double(forKey: "balance") // Load balance from UserDefaults
    
    @State private var isIncomeViewPresented = false // Control the presentation of IncomeView
    @State private var isExpenseViewPresented = false // Control the presentation of ExpenseView
    @State private var isIncomeHistoryViewPresented = false // Control the presentation of IncomeHistoryView
    @State private var isExpenseHistoryViewPresented = false // Control the presentation of ExpenseHistoryView
    
    // Colors to display
    let colors: [Color] = [.green, .red] // Replace with your desired colors
    
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
                VStack{
                    Circle()
                        .fill(colors[currentColorIndex])
                        .frame(width: 300, height: 300) // Use a fixed size circle
                        .transition(.scale)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)){
                                if colors[currentColorIndex] == .green {
                                    isIncomeHistoryViewPresented = true
                                }else{
                                    isExpenseHistoryViewPresented = true
                                }
                            }
                        }
                    
                    
                    // Navigation Button
                    Button(action: { showNextColor() }) {
                        Image(systemName: colors[currentColorIndex] == .green ? "plus.circle.fill" : "minus.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.primary)
                    }
                    .padding()
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
                .sheet(isPresented: $isIncomeHistoryViewPresented){
                    IncomeHistoryView(isPresented: $isIncomeHistoryViewPresented)
                }.sheet(isPresented: $isExpenseHistoryViewPresented){
                    ExpenseHistoryView(isPresented: $isExpenseHistoryViewPresented)
                }
            }
            .navigationBarTitle("MyBudget", displayMode: .large)
        }
        .onAppear(){
            incomeManager.loadIncomes()
            expenseManager.loadExpenses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            balance = UserDefaults.standard.double(forKey: "balance")
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
}

#Preview {
    MainView()
}
