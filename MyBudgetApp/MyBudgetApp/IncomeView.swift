import SwiftUI

struct Income: Identifiable,Codable{
    var id = UUID()
    var name: String
    var category: String
    var amount: Double
    var frequency: String
    var customYear: Int?
    var customMonth: Int?
    var customDay: Int?
    var isArchived: Bool = false
}

class IncomeManager: ObservableObject {
    @Published var incomes: [Income] = []
    
    var totalIncome: Double {
        return incomes.reduce(0) { $0 + $1.amount }
    }
    
    var incomesByCategory: [String: Double] {
        return Dictionary(grouping: incomes.filter { !$0.isArchived }, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    
    // Function to add an income item to the list
    func addIncome(_ income: Income) {
        incomes.append(income)
        saveIncomes()
    }
    
    // Function to save the incomes to UserDefaults
    func saveIncomes() {
        if let encodedData = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encodedData, forKey: "incomes")
        }
    }
    
    // Function to load incomes from UserDefaults
    func loadIncomes() {
        if let encodedData = UserDefaults.standard.data(forKey: "incomes") {
            if let savedIncomes = try? JSONDecoder().decode([Income].self, from: encodedData) {
                self.incomes = savedIncomes
            }
        }
    }
    
    // Function to remove an income item from the list
    func removeIncome(at offsets: IndexSet) {
        // Get the amount to be subtracted from the balance
        let amountToSubtract = incomes[offsets.first!].amount
        // Remove the income from the list
        incomes.remove(atOffsets: offsets)
        // Save the updated list to UserDefaults
        saveIncomes()
        
        // Update the balance in UserDefaults
        let currentBalance = UserDefaults.standard.double(forKey: "balance")
        UserDefaults.standard.set(currentBalance - amountToSubtract, forKey: "balance")
    }
}

struct IncomeView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var activeSheet: ActiveSheet? //Binding to control the presentation of IncomeView
    
    @State private var incomeName = ""
    @State private var incomeAmount = ""
    
    ///Categories
    let incomeCategoryOptions = ["Work", "Gifts", "Other"]
    @State private var selectedCategory = "Work" //Default category
    
    ///Frequency
    let frequencyOptions = ["One-time", "Every day", "Every week", "Every month", "Every year", "Other"]
    @State private var selectedFrequency = "One-time" //Default frequency
    @State private var customYear: Int = 0
    @State private var customMonth: Int = 0
    @State private var customDay: Int = 0
    
    
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
                    
                    Section {
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(frequencyOptions, id: \.self) { frequency in
                                Text(frequency)
                            }
                        }
                        
                        if selectedFrequency == "Other" {
                            HStack {
                                Picker("", selection: $customYear) {
                                    ForEach(0..<21) { year in
                                        Text("\(year) year\(year != 1 ? "s" : "")")
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 80)
                                
                                Picker("", selection: $customMonth) {
                                    ForEach(0..<12) { month in
                                        Text("\(month) month\(month != 1 ? "s" : "")")
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 100)
                                
                                Picker("", selection: $customDay) {
                                    ForEach(0..<31) { day in
                                        Text("\(day) day\(day != 1 ? "s" : "")")
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 80)
                            }
                        }
                    }
                    
                }
                .navigationTitle("Add income")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: Button(action: {
                        // Handle the action to go back to the MainView
                        activeSheet = nil // Dismiss the IncomeView
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.blue)
                    }
                )
                
                Spacer()
                
                Button(action: {
                    addIncome()
                })
                {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(incomeName.isEmpty || incomeAmount.isEmpty ? .gray : .blue)
                        .overlay(Image(systemName: "plus").font(.title).foregroundColor(.white))
                        .background(Color.clear)
                }
                .disabled(incomeName.isEmpty || incomeAmount.isEmpty) // Disable the button if fields are empty
                .padding()
            }
        }
    }
    
    private func addIncome() {
        if let number = Double(incomeAmount.replacingOccurrences(of: ",", with: ".")) {
            mainViewBalance += number
            
            // Update UserDefaults balance value here
            UserDefaults.standard.set(mainViewBalance, forKey: "balance")
            UserDefaults.standard.synchronize() // Force immediate synchronization
            
            let newIncome = Income(name: incomeName, category: selectedCategory, amount: number, frequency: selectedFrequency, customYear: selectedFrequency == "Other" ? customYear : nil, customMonth: selectedFrequency == "Other" ? customMonth : nil, customDay: selectedFrequency == "Other" ? customDay : nil)
            
            incomeManager.addIncome(newIncome)
            activeSheet = nil // Dismiss the IncomeView
        }
    }

}

#Preview {
    IncomeView(mainViewBalance: .constant(100.0), activeSheet: .constant(.incomeView))
        .environmentObject(IncomeManager())
}
