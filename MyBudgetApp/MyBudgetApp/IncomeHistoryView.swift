import SwiftUI


struct IncomeHistoryView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            List{
                ForEach(incomeManager.incomes.filter { !$0.isArchived }.reversed()) { income in
                    VStack(alignment: .leading) {
                        Text("\(income.name)")
                            .fontWeight(.bold)
                        Text("Category: \(income.category)")
                        Text("Amount: ")
                            + Text("\(formatAsCurrency(amount: income.amount))")
                                .fontWeight(.heavy)
                        if income.frequency == "Other", let year = income.customYear, let month = income.customMonth, let day = income.customDay {
                            Text("Frequency: Every \(year > 0 ? "\(year) year\(year != 1 ? "s" : ""), " : "")\(month > 0 ? "\(month) month\(month != 1 ? "s" : ""), " : "")\(day > 0 ? "\(day) day\(day != 1 ? "s" : "")" : "")")
                        } else {
                            Text("Frequency: \(income.frequency)")
                        }
                    }
                }
                .onDelete(perform: deleteIncome)
            }
            .navigationBarTitle("Income History") ///CHANGE TO Income history for the month of...
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
    
    func deleteIncome(at offsets: IndexSet) {
        let incomesToDelete = offsets.compactMap { incomeManager.incomes.reversed()[$0] }
        for income in incomesToDelete {
            if income.category != "Monthly budget" {
                if let index = incomeManager.incomes.firstIndex(where: { $0.id == income.id }) {
                    incomeManager.incomes.remove(at: index)
                }
            }
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
