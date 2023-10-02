import SwiftUI

struct Expense: Identifiable,Codable{
    var id = UUID()
    var name: String
    var category: String
    var amount: Double
}

class ExpenseManager: ObservableObject {
    @Published var expenses: [Expense] = []
    
    // Function to add an expense item to the list
    func addExpense(name: String, category: String, amount: Double) {
        let newExpense = Expense(name: name, category: category, amount: amount)
        expenses.append(newExpense)
        saveExpenses()
    }
    
    // Function to save the expenses to UserDefaults
    func saveExpenses() {
        if let encodedData = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedData, forKey: "expenses")
        }
    }
    
    // Function to load expenses from UserDefaults
    func loadExpenses() {
        if let encodedData = UserDefaults.standard.data(forKey: "expenses") {
            if let savedExpenses = try? JSONDecoder().decode([Expense].self, from: encodedData) {
                self.expenses = savedExpenses
            }
        }
    }
    
    // Function to remove an income item from the list
    func removeExpense(at offsets: IndexSet) {
        // Get the amount to be subtracted from the balance
        let amountToAdd = expenses[offsets.first!].amount
        // Remove the income from the list
        expenses.remove(atOffsets: offsets)
        // Save the updated list to UserDefaults
        saveExpenses()
        
        // Update the balance in UserDefaults
        let currentBalance = UserDefaults.standard.double(forKey: "balance")
        UserDefaults.standard.set(currentBalance + amountToAdd, forKey: "balance")
    }
}

struct ExpenseView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var isPresented: Bool // Binding to control the presentation of expenseView
    
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    
    let expenseCategoryOptions = ["Social", "Food", "Work", "Health", "Entertainment", "Clothing", "Travel", "Other"]
    @State private var selectedCategory = "Social" //Default category
    
    
    var body: some View {
        NavigationView {
            VStack{
                List{
                    Section{
                        TextField("Expense Name", text: $expenseName)
                            .keyboardType(.default)
                            .padding()
                        
                        TextField("Expense Amount", text: $expenseAmount)
                            .padding()
                            .keyboardType(.decimalPad) // Use .decimalPad for decimal input
                    }
                    
                    Section{
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(expenseCategoryOptions, id: \.self) { category in
                                Text(category)
                            }
                        }
                    }
                }
                
                
                Spacer()
                
                Button(action: {
                    addExpense()
                })
                {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(expenseName.isEmpty || expenseAmount.isEmpty ? .gray : .blue)
                        .overlay(Image(systemName: "minus").font(.title).foregroundColor(.white))
                        .background(Color.clear)
                }
                .disabled(expenseName.isEmpty || expenseAmount.isEmpty) // Disable the button if fields are empty
                .padding()
            }
            .navigationTitle("Add expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    // Handle the action to go back to the MainView
                    isPresented = false // Dismiss the expenseView
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
            )
        }
    }
    
    private func addExpense(){
        // Preprocess the input to replace commas with periods
        // Validate and update balance
        if let number = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) {
            mainViewBalance -= number
            
            // Update UserDefaults balance value here
            UserDefaults.standard.set(mainViewBalance, forKey: "balance")
            UserDefaults.standard.synchronize() // Force immediate synchronization
            
            expenseManager.addExpense(name: expenseName, category: selectedCategory, amount: number)
        }
        isPresented = false // Dismiss the expenseView
    }
}






#Preview {
    ExpenseView(mainViewBalance: .constant(100.0), isPresented: .constant(true))
        .environmentObject(ExpenseManager())
}
