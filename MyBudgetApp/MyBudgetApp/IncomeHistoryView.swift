import SwiftUI

struct IncomeHistoryView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(incomeManager.incomes.reversed()) { income in
                    VStack(alignment: .leading) {
                        Text("\(income.name)")
                            .fontWeight(.bold)
                        Text("Category: \(income.category)")
                        Text("Amount: ")
                            + Text("\(formatAsCurrency(amount: income.amount))")
                                .fontWeight(.heavy)
                    }
                }
                .onDelete { offsets in
                    let reversedOffsets = offsets.map { incomeManager.incomes.count - 1 - $0 }
                    incomeManager.removeIncome(at: IndexSet(reversedOffsets))
                }
            }
            .navigationBarTitle("Income History")
            .navigationBarItems(
                leading: Button(action: {
                    // Handle the action to go back to the MainView
                    activeSheet = nil // Dismiss the IncomeView
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
    IncomeHistoryView(activeSheet: .constant(.incomeHistoryView))
        .environmentObject(IncomeManager())
}
