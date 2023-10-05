import SwiftUI

struct BeginningBudgetView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var activeSheet: ActiveSheet?
    
    @State private var incomeName = "Budget for the month"
    @State private var incomeAmount = ""
    
    //let incomeCategoryOptions = ["Beginning Budget"]
    let selectedCategory = "Monthly budget" //Default category
    let selectedFrequency = "Every month"
    
    
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center){
                
                Spacer()
                
                TextField("1234.56*", text: $incomeAmount)
                    .multilineTextAlignment(.center)
                    //.border(Color.black)
                    .padding(.horizontal, 15.0)
                    .keyboardType(.decimalPad) // Use .decimalPad for decimal input
                    .font(.system(size: 75))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { addIncome() })
                {
                    Image(systemName: "plus.circle.fill")
                        //.font(.largeTitle)
                        .font(.system(size: 60))
                        .foregroundColor(incomeAmount.isEmpty ? .gray : .green)
                        .background(Color.clear)
                }
                .disabled(incomeAmount.isEmpty) // Disable the button if fields are empty
                .padding()
                
                Text("*This budget will reset every 1st of the month, you can modify your budget at any time")
                    .fontWeight(.thin)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("ADD MONTHLY BUDGET")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func addIncome(){
        // Preprocess the input to replace commas with periods
        // Validate and update balance
        if let number = Double(incomeAmount.replacingOccurrences(of: ",", with: ".")) {
            mainViewBalance = number
            
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            let monthName = dateFormatter.string(from: currentDate)
            
            // Update UserDefaults balance value here
            UserDefaults.standard.set(mainViewBalance, forKey: "balance")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.synchronize() // Force immediate synchronization
            let newIncome = Income(name: "Budget for \(monthName)", category: "Monthly budget", amount: number, frequency: "Every month", customYear: nil, customMonth: nil, customDay: nil)
            incomeManager.addIncome(newIncome)
        }
        activeSheet = nil // Dismiss the IncomeView
    }
}

#Preview {
    BeginningBudgetView(mainViewBalance: .constant(100.0), activeSheet: .constant(.beginningBudgetView))
        .environmentObject(IncomeManager())
}
