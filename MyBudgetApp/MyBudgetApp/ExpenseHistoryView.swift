import SwiftUI

struct ExpenseHistoryView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
                    List {
                        ForEach(expenseManager.expenses) { expense in
                            VStack(alignment: .leading) {
                                Text("\(expense.name)")
                                    .fontWeight(.bold)
                                Text("Category: \(expense.category)")
                                Text("Amount: ")
                                    + Text("- \(formatAsCurrency(amount: expense.amount))")
                                        .fontWeight(.heavy)
                            }
                        }
                        .onDelete(perform: expenseManager.removeExpense) // This enables swipe-to-delete
                    }
                    .navigationBarTitle("Expense History")
                    .navigationBarItems(
                        leading: Button(action: {
                            // Handle the action to go back to the MainView
                            isPresented = false // Dismiss the ExpenseView
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.blue)
                        }
                    )
                }
    }
    
    func formatAsCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "" // Remove the default currency symbol
        formatter.locale = Locale.current
        
        // Get the formatted string without the currency symbol
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        
        // Append the currency symbol at the end
        if let currencySymbol = Locale.current.currencySymbol {
            return "\(formattedAmount)\(currencySymbol)"
        } else {
            return formattedAmount
        }
    }

}


#Preview {
    ExpenseHistoryView(isPresented: .constant(true))
        .environmentObject(ExpenseManager())
}
