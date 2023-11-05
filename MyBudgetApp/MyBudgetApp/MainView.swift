import SwiftUI

enum ActiveSheet: Identifiable {
    case incomeView, expenseView, incomeHistoryView, expenseHistoryView, beginningBudgetView
    
    var id: Int {
        hashValue
    }
}

enum TransactionType {
    case income
    case expense
}

struct PieChartData: Hashable {
    var category: EntryType
    var amount: Double
    var color: Color
    var type: TransactionType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(amount)
        // I'll use the description of the color for hashing
        hasher.combine(color.description)
    }
    
    static func == (lhs: PieChartData, rhs: PieChartData) -> Bool {
        return lhs.category == rhs.category && lhs.amount == rhs.amount && lhs.color.description == rhs.color.description
    }
}

enum EntryType {
    case income
    case expense
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        )
        
        var path = Path()
        path.move(to: center)
        path.addLine(to: start)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: center)
        
        return path
    }
}


struct MainView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    @EnvironmentObject var expenseManager: ExpenseManager
    
    // User's current balance
    @State private var balance: Double = UserDefaults.standard.double(forKey: "balance")
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var cumulativeAngle: Double = 0.0
    
    @State private var dataUpdated: Bool = false
    
    var startingBudgetOfMonth: Double {
        return UserDefaults.standard.double(forKey: "startingBudgetOfMonth")
    }
    
    var pieChartData: [PieChartData] {
        var data: [PieChartData] = []
        
        // Grouped incomes
        let groupedIncomes = Dictionary(grouping: incomeManager.incomes, by: { $0.category })
        for (category, incomes) in groupedIncomes {
            let totalAmount = incomes.reduce(0) { $0 + $1.amount }
            let color = colorForIncome(category: category)
            data.append(PieChartData(category: .income, amount: totalAmount, color: color, type: .income))
        }
        
        // Grouped expenses
        let groupedExpenses = Dictionary(grouping: expenseManager.expenses, by: { $0.category })
        for (category, expenses) in groupedExpenses {
            let totalAmount = expenses.reduce(0) { $0 + $1.amount }
            let color = colorForExpense(category: category)
            data.append(PieChartData(category: .expense, amount: totalAmount, color: color, type: .expense))
        }
        
        return data
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(formatAsCurrency(amount: balance))
                    .font(.largeTitle)
                    .foregroundColor(balance < 0 ? Color.red : Color.black)
                    .padding(.top)
                
                Text("(\(formatAsCurrency(amount: startingBudgetOfMonth)))")
                    .font(.caption)
                    .fontWeight(.light)
                
                VStack {
                    PieChartView(data: pieChartData, activeSheet: $activeSheet)
                        .frame(width: 300, height: 300)
                        .id(pieChartData)
                        .id(dataUpdated)
                }
                
                Spacer()
                
                HStack(spacing: 40) {
                    // Expense View Button
                    Button(action: { activeSheet = .expenseView }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    //Set next month's budget button
                    Button(action: { activeSheet = .beginningBudgetView }) {
                        Image(systemName: "house.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    
                    // Income View Button
                    Button(action: { activeSheet = .incomeView }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .incomeView:
                        IncomeView(mainViewBalance: $balance, activeSheet: $activeSheet)
                    case .expenseView:
                        ExpenseView(mainViewBalance: $balance, activeSheet: $activeSheet)
                    case .incomeHistoryView:
                        IncomeHistoryView(activeSheet: $activeSheet)
                    case .expenseHistoryView:
                        ExpenseHistoryView(activeSheet: $activeSheet)
                    case .beginningBudgetView:
                        BeginningBudgetView(mainViewBalance: $balance, activeSheet: $activeSheet)
                            .environmentObject(incomeManager)
                    }
                    
                }
            }
            .navigationBarTitle("MyBudget", displayMode: .large)
        }
        .onAppear() {
            cumulativeAngle = 0.0
            
            // 1. Load all incomes and expenses from storage.
            incomeManager.loadIncomes()
            expenseManager.loadExpenses()
            
            // 2. Deduct scheduled expenses and add scheduled incomes.
            deductScheduledExpenses()
            addScheduledIncomes()
            
            //3. Check and reset the balance if need be
            checkAndResetBalance()
            
            // 4. Update any expenses and incomes that don't have a nextScheduledDate set.
            for index in expenseManager.expenses.indices {
                if expenseManager.expenses[index].nextScheduledDate == nil {
                    expenseManager.expenses[index].nextScheduledDate = expenseManager.getNextScheduledDate(for: expenseManager.expenses[index])
                }
            }
            for index in incomeManager.incomes.indices {
                if incomeManager.incomes[index].nextScheduledDate == nil {
                    incomeManager.incomes[index].nextScheduledDate = incomeManager.getNextScheduledDate(for: incomeManager.incomes[index])
                }
            }
            
            // 5. Save any changes made to the expenses and incomes.
            expenseManager.saveExpenses()
            incomeManager.saveIncomes()

            // 6. Handle the first-time launch scenario.
            if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                activeSheet = .beginningBudgetView //Control the presentation of the beginningBudgetView
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            balance = UserDefaults.standard.double(forKey: "balance")
        }
    }
    
    
    
    
    /// Update the balance in UserDefaults when it changes
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
    
//    ///Reset the monthly budget every 1st of the month
//    
    func getLatestMonthlyBudget() -> Double? {
        for income in incomeManager.incomes.reversed() {
            if income.category == "Monthly budget" {
                return income.amount
            }
        }
        return nil
    }
    
    func checkAndResetBalance() {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let monthName = dateFormatter.string(from: currentDate)
        let calendar = Calendar.current
        
        let lastOpenedDate = UserDefaults.standard.object(forKey: "lastOpenedDate") as? Date ?? Date()
        let lastOpenedComponents = calendar.dateComponents([.year, .month], from: lastOpenedDate)
        let currentComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        if lastOpenedComponents.month != currentComponents.month {
            let lastResetMonth = UserDefaults.standard.integer(forKey: "lastResetMonth")
            let currentMonth = calendar.component(.month, from: currentDate)
            
            if lastResetMonth != currentMonth {
                // Check if there's a new budget set for the next month
                if let nextMonthBudget = UserDefaults.standard.value(forKey: "nextMonthBudget") as? Double {
                    balance = nextMonthBudget
                    UserDefaults.standard.removeObject(forKey: "nextMonthBudget")
                } else if let monthlyBudget = getLatestMonthlyBudget() {
                    balance = monthlyBudget
                }
                
                UserDefaults.standard.set(currentMonth, forKey: "lastResetMonth")
                UserDefaults.standard.set(balance, forKey: "balance")
                UserDefaults.standard.set(balance, forKey: "startingBudgetOfMonth")
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                UserDefaults.standard.synchronize()
                
                // Archive all current incomes and adjust balance
                for index in incomeManager.incomes.indices.reversed() where calendar.component(.month, from: incomeManager.incomes[index].creationDate) != currentMonth {
                    // Check if the income has been claimed
                    if let nextDate = incomeManager.incomes[index].nextScheduledDate, nextDate <= Date() {
                        incomeManager.incomes[index].isArchived = true
                        incomeManager.incomes.remove(at: index)
                    }
                }

                // Archive all current expenses and adjust balance
                for index in expenseManager.expenses.indices.reversed() where calendar.component(.month, from: expenseManager.expenses[index].creationDate) != currentMonth {
                    // Check if the expense has been claimed
                    if let nextDate = expenseManager.expenses[index].nextScheduledDate, nextDate <= Date() {
                        expenseManager.expenses[index].isArchived = true
                        expenseManager.expenses.remove(at: index)
                    }
                }

                
                dataUpdated.toggle()
                // Save the updated incomes and expenses
                incomeManager.saveIncomes()
                expenseManager.saveExpenses()
                
                // Add the new budget to the IncomeHistoryView
                let newIncome = Income(name: "Budget for \(monthName)", category: "Monthly budget", amount: balance, frequency: "One-time", customYear: nil, customMonth: nil, customDay: nil, creationDate: Date())
                incomeManager.addIncome(newIncome)
            }
        }

        UserDefaults.standard.set(currentDate, forKey: "lastOpenedDate")
    }
     
    
    func deductScheduledExpenses() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let lastOpenedDate = UserDefaults.standard.object(forKey: "lastOpenedDate") as? Date ?? Date()
        var pseudoDate = Calendar.current.date(byAdding: .day, value: 1, to: lastOpenedDate)!
        
        print("Current Date: \(currentDate)")
        print("Total number of expenses: \(expenseManager.expenses.count)")
        
        while pseudoDate <= currentDate {
            var expensesDeductedToday: [String] = [] // To keep track of expenses deducted for the current pseudoDate
            var checkedExpenses: Set<String> = [] // To keep track of expenses that have been checked for the current pseudoDate
            
            for index in expenseManager.expenses.indices {
                var expense = expenseManager.expenses[index]
                
                if checkedExpenses.contains(expense.name) {
                    continue
                }
                
                print("Checking expense: \(expense.name) with next scheduled date: \(String(describing: expense.nextScheduledDate))")
                
                if let nextDate = expense.nextScheduledDate, pseudoDate >= nextDate, !expensesDeductedToday.contains(expense.name) {
                    
                    print("Deducting \(expense.amount) for \(expense.name)")
                    
                    balance -= expense.amount
                    UserDefaults.standard.set(balance, forKey: "balance")
                    UserDefaults.standard.synchronize()
                    
                    // Update the nextScheduledDate for this expense based on its frequency
                    switch expense.frequency {
                    case "Every day":
                        expense.nextScheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)
                    case "Every week":
                        expense.nextScheduledDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextDate)
                    case "Every month":
                        expense.nextScheduledDate = Calendar.current.date(byAdding: .month, value: 1, to: nextDate)
                    case "Every year":
                        expense.nextScheduledDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDate)
                    case "Other":
                        var newDate: Date? = nextDate
                        if let day = expense.customDay {
                            newDate = Calendar.current.date(byAdding: .day, value: day, to: newDate!)
                        }
                        if let month = expense.customMonth {
                            newDate = Calendar.current.date(byAdding: .month, value: month, to: newDate!)
                        }
                        if let year = expense.customYear {
                            newDate = Calendar.current.date(byAdding: .year, value: year, to: newDate!)
                        }
                        expense.nextScheduledDate = newDate
                    default:
                        break
                    }
                    
                    // Create a new expense entry for the deduction with the pseudoDate as its creation date
                    var deductedExpense = Expense(name: expense.name, category: expense.category, amount: expense.amount, frequency: expense.frequency, customYear: nil, customMonth: nil, customDay: nil, creationDate: pseudoDate)
                    deductedExpense.nextScheduledDate = expense.nextScheduledDate
                    expenseManager.addExpense(deductedExpense)
                    
                    expensesDeductedToday.append(expense.name) // Add the expense name to the list of expenses deducted for the current pseudoDate
                }
                checkedExpenses.insert(expense.name) // Add the expense name to the set of checked expenses for the current pseudoDate
                expenseManager.expenses[index] = expense
            }
            
            pseudoDate = Calendar.current.date(byAdding: .day, value: 1, to: pseudoDate)!
        }
        
        // Remove all expenses that were created in a different month than the current one
        expenseManager.expenses.removeAll(where: { calendar.component(.month, from: $0.creationDate) != currentMonth })
        expenseManager.saveExpenses()
    }

    func addScheduledIncomes() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let lastOpenedDate = UserDefaults.standard.object(forKey: "lastOpenedDate") as? Date ?? Date()
        var pseudoDate = Calendar.current.date(byAdding: .day, value: 1, to: lastOpenedDate)!
        
        print("Current Date: \(currentDate)")
        print("Total number of incomes: \(incomeManager.incomes.count)")
        
        while pseudoDate <= currentDate {
            var incomesAddedToday: [String] = [] // To keep track of expenses deducted for the current pseudoDate
            var checkedIncomes: Set<String> = [] // To keep track of expenses that have been checked for the current pseudoDate
            
            for index in incomeManager.incomes.indices {
                var income = incomeManager.incomes[index]
                
                if checkedIncomes.contains(income.name) {
                    continue
                }
                
                print("Checking income: \(income.name) with next scheduled date: \(String(describing: income.nextScheduledDate))")
                
                if let nextDate = income.nextScheduledDate, pseudoDate >= nextDate, !incomesAddedToday.contains(income.name) {
                    
                    print("Adding \(income.amount) for \(income.name)")
                    
                    balance += income.amount
                    UserDefaults.standard.set(balance, forKey: "balance")
                    UserDefaults.standard.synchronize()
                    
                    // Update the nextScheduledDate for this expense based on its frequency
                    switch income.frequency {
                    case "Every day":
                        income.nextScheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)
                    case "Every week":
                        income.nextScheduledDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextDate)
                    case "Every month":
                        income.nextScheduledDate = Calendar.current.date(byAdding: .month, value: 1, to: nextDate)
                    case "Every year":
                        income.nextScheduledDate = Calendar.current.date(byAdding: .year, value: 1, to: nextDate)
                    case "Other":
                        var newDate: Date? = nextDate
                        if let day = income.customDay {
                            newDate = Calendar.current.date(byAdding: .day, value: day, to: newDate!)
                        }
                        if let month = income.customMonth {
                            newDate = Calendar.current.date(byAdding: .month, value: month, to: newDate!)
                        }
                        if let year = income.customYear {
                            newDate = Calendar.current.date(byAdding: .year, value: year, to: newDate!)
                        }
                        income.nextScheduledDate = newDate
                    default:
                        break
                    }
                    
                    // Create a new expense entry for the deduction with the pseudoDate as its creation date
                    var addedIncome = Income(name: income.name, category: income.category, amount: income.amount, frequency: income.frequency, customYear: nil, customMonth: nil, customDay: nil, creationDate: pseudoDate)
                    addedIncome.nextScheduledDate = income.nextScheduledDate
                    incomeManager.addIncome(addedIncome)
                    
                    incomesAddedToday.append(income.name) // Add the expense name to the list of expenses deducted for the current pseudoDate
                }
                checkedIncomes.insert(income.name) // Add the expense name to the set of checked expenses for the current pseudoDate
                incomeManager.incomes[index] = income
            }
            
            pseudoDate = Calendar.current.date(byAdding: .day, value: 1, to: pseudoDate)!
        }
        
        // Remove all expenses that were created in a different month than the current one
        incomeManager.incomes.removeAll(where: { calendar.component(.month, from: $0.creationDate) != currentMonth })
        incomeManager.saveIncomes()
    }
    
    ///Pie chart
    
    func startAngle(for percentage: Double) -> Double {
        let start = cumulativeAngle
        cumulativeAngle += 360 * percentage
        return start
    }
    
    func endAngle(for percentage: Double) -> Double {
        return cumulativeAngle
    }
    
    func colorForIncome(category: String) -> Color {
        switch category {
        case "Work":
            return .income2
        case "Gifts":
            return .income3
        case "Other":
            return .income4
        default:
            return .income1
        }
    }
    
    func colorForExpense(category: String) -> Color {
        switch category {
        case "Personal":
            return .expense1
        case "Food":
            return .expense2
        case "Work":
            return .expense3
        case "Health":
            return .expense4
        case "Gifts":
            return .expense5
        case "Travel":
            return .expense6
        case "Bills":
            return .expense7
        default:
            return .expense8
        }
    }
    
    ///Other
    func formatAsCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
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
    MainView()
        .environmentObject(IncomeManager())
        .environmentObject(ExpenseManager())
}


///KNOWN BUGS TO FIX:
///-Frequent incomes/expenses not updating correctly when changing months. example:
///    (FIXED) Income/Expense set as daily with value of 1 on october 10th. When opening the app on november 4th (25 days later) it adds/deducts the value 25 times.
///             -New problem: Its adding the expenses/incomes correctly now, but it's not updating the balance
///
///
///
///     Not tested yet but definitely also gives problems with weekly, and custom. Monthly and yearly works fine
