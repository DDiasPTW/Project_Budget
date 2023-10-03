import SwiftUI

struct BeginningBudgetView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var isPresented: Bool // Binding to control the presentation of IncomeView
    
    @State private var incomeName = ""
    @State private var incomeAmount = ""
    
    let incomeCategoryOptions = ["Work", "Gifts", "Insurance", "Other"]
    @State private var selectedCategory = "Work" //Default category
    
    
    var body: some View {
        NavigationView {
            VStack{
                List{
                    TextField("Income Name", text: $incomeName)
                        .keyboardType(.default)
                        .padding()
                    
                    TextField("Income Amount", text: $incomeAmount)
                        .padding()
                        .keyboardType(.decimalPad) // Use .decimalPad for decimal input
                    
                    Section{
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(incomeCategoryOptions, id: \.self) { category in
                                Text(category)
                            }
                        }
                    }
                }
                .navigationTitle("ADD BUDGET")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                
                Spacer()
                
                Button(action: {
                    addIncome()
                })
                {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(incomeName.isEmpty || incomeAmount.isEmpty ? .gray : .green)
                        .overlay(Image(systemName: "plus").font(.title).foregroundColor(.white))
                        .background(Color.clear)
                }
                .disabled(incomeName.isEmpty || incomeAmount.isEmpty) // Disable the button if fields are empty
                .padding()
            }
        }
    }
    
    private func addIncome(){
        // Preprocess the input to replace commas with periods
        // Validate and update balance
        if let number = Double(incomeAmount.replacingOccurrences(of: ",", with: ".")) {
            mainViewBalance += number
            
            // Update UserDefaults balance value here
            UserDefaults.standard.set(mainViewBalance, forKey: "balance")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.synchronize() // Force immediate synchronization
            incomeManager.addIncome(name: incomeName, category: selectedCategory, amount: number)
        }
        isPresented = false // Dismiss the IncomeView
    }
}

#Preview {
    BeginningBudgetView(mainViewBalance: .constant(100.0), isPresented: .constant(true))
        .environmentObject(IncomeManager())
}
