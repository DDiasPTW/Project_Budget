import SwiftUI

struct ExpenseView: View {
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var isPresented: Bool // Binding to control the presentation of IncomeView
    
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false // Dismiss the IncomeView
                    }) {
                        Image(systemName: "arrow.left")
                            .padding()
                    }
                    Spacer()
                }
                
                TextField("Expense Name", text: $expenseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .padding()
                
                TextField("Expense Amount", text: $expenseAmount, onCommit: {
                    // Preprocess the input to replace commas with periods
                    // Validate and update balance when editing is finished
                    if let number = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) {
                        mainViewBalance -= number
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.decimalPad) // Use .decimalPad for decimal input
                
                Spacer()
                
                Button(action: {
                    // Preprocess the input to replace commas with periods
                    // Validate and update balance
                    if let number = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) {
                        mainViewBalance -= number
                        
                        // Update UserDefaults balance value here
                        UserDefaults.standard.set(mainViewBalance, forKey: "balance")
                        UserDefaults.standard.synchronize() // Force immediate synchronization
                    }
                    isPresented = false // Dismiss the IncomeView
                }) {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(expenseName.isEmpty || expenseAmount.isEmpty ? .gray : .blue)
                        .overlay(Image(systemName: "minus").font(.title).foregroundColor(.white))
                }
                .disabled(expenseName.isEmpty || expenseAmount.isEmpty) // Disable the button if fields are empty
                .padding()
            }
            .navigationTitle("Add expense")
        }
    }
}
