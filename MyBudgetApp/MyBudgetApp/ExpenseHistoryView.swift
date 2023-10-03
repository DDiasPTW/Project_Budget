import SwiftUI

struct ExpenseHistoryView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
                    List {
                        ForEach(expenseManager.expenses.reversed()) { expense in
                            VStack(alignment: .leading) {
                                Text("\(expense.name)")
                                    .fontWeight(.bold)
                                Text("Category: \(expense.category)")
                                Text("Amount: ")
                                    + Text("- \(formatAsCurrency(amount: expense.amount))")
                                        .fontWeight(.heavy)
                            }
                        }
                        .onDelete { offsets in
                            let reversedOffsets = offsets.map { expenseManager.expenses.count - 1 - $0 }
                            expenseManager.removeExpense(at: IndexSet(reversedOffsets))
                        }
                    }
                    .navigationBarTitle("Expense History")
                    .navigationBarItems(
                        leading: Button(action: {
                            // Handle the action to go back to the MainView
                            activeSheet = nil // Dismiss the ExpenseView
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
    ExpenseHistoryView(activeSheet: .constant(.expenseHistoryView))
        .environmentObject(ExpenseManager())
}
