import SwiftUI

enum ActiveSheet: Identifiable {
    case incomeView, expenseView, incomeHistoryView, expenseHistoryView, beginningBudgetView
    
    var id: Int {
        hashValue
    }
}

struct MainView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    @EnvironmentObject var expenseManager: ExpenseManager
    
    // User's current balance
    @State private var balance: Double = UserDefaults.standard.double(forKey: "balance") // Load balance from UserDefaults
    
    @State private var isIncomeViewPresented = false // Control the presentation of IncomeView
    @State private var isExpenseViewPresented = false // Control the presentation of ExpenseView
    @State private var isIncomeHistoryViewPresented = false // Control the presentation of IncomeHistoryView
    @State private var isExpenseHistoryViewPresented = false // Control the presentation of ExpenseHistoryView
    @State private var showBeginningBudgetView: Bool = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") //Control if it's the first time the user is opening the app
    @State private var showingIncomeChart: Bool = true
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var cumulativeAngle: Double = 0.0
    
    init() {
        print("Initial balance loaded:", balance)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(formatAsCurrency(amount: balance))
                    .font(.largeTitle)
                    .padding()
                
                VStack {
                    if showingIncomeChart {
                        PieChartIncomeView()
                            .frame(width: 300, height: 300)
                            .onTapGesture {
                                activeSheet = .incomeHistoryView
                            }
                    } else {
                        PieChartExpenseView()
                            .frame(width: 300, height: 300)
                            .onTapGesture {
                                activeSheet = .expenseHistoryView
                            }
                    }
                    
                    Button(action: {
                        showingIncomeChart.toggle()
                    }) {
                        Image(systemName: showingIncomeChart ? "plus.circle.fill" : "minus.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.accentColor)
                    }
                    .padding()
                }
                
                
                Spacer()
                
                HStack(spacing: 100) {
                    // Expense View Button
                    Button(action: { activeSheet = .expenseView }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    .padding()
                    
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
                        BeginningBudgetView(mainViewBalance: $balance, isPresented: $showBeginningBudgetView)
                            .environmentObject(incomeManager)
                    }
                }
            }
            .navigationBarTitle("MyBudget", displayMode: .large)
        }
        .onAppear(){
            cumulativeAngle = 0.0
            incomeManager.loadIncomes()
            expenseManager.loadExpenses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            balance = UserDefaults.standard.double(forKey: "balance")
        }
    }
    
    // Update the balance in UserDefaults when it changes
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
    
    func startAngle(for percentage: Double) -> Double {
        let start = cumulativeAngle
        cumulativeAngle += 360 * percentage
        return start
    }
    
    func endAngle(for percentage: Double) -> Double {
        return cumulativeAngle
    }
    
    func colorIncomes(for category: String) -> Color {
        switch category {
        case "Work":
            return .green
        case "Gifts":
            return .blue
        case "Insurance":
            return .orange
        default:
            return .pink
        }
    }
    
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

#Preview {
    MainView()
        .environmentObject(IncomeManager())
        .environmentObject(ExpenseManager())
}
