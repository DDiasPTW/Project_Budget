import SwiftUI

extension Color{
    static let expense1 = Color(red: 90/255, green: 17/255, blue: 12/255)
    static let expense2 = Color(red: 108/255, green: 21/255, blue: 15/255)
    static let expense3 = Color(red: 126/255, green: 24/255, blue: 17/255)
    static let expense4 = Color(red: 144/255, green: 28/255, blue: 20/255)
    static let expense5 = Color(red: 162/255, green: 31/255, blue: 22/255)
    static let expense6 = Color(red: 180/255, green: 35/255, blue: 24/255)
    static let expense7 = Color(red: 197/255, green: 38/255, blue: 27/255)
    static let expense8 = Color(red: 215/255, green: 42/255, blue: 29/255)
    static let expense9 = Color(red: 226/255, green: 52/255, blue: 40/255)
}

struct PieChartExpenseView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    
    var angles: [(start: Double, end: Double)] {
        var cumulativeAngle: Double = 0.0
        var result: [(start: Double, end: Double)] = []
        
        for category in expenseManager.expensesByCategory.keys.sorted() {
            let percentage = expenseManager.expensesByCategory[category, default: 0] / expenseManager.totalExpense
            let start = cumulativeAngle
            cumulativeAngle += 360 * percentage
            let end = cumulativeAngle
            result.append((start, end))
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(zip(expenseManager.expensesByCategory.keys.sorted(), angles)), id: \.0) { category, angle in
                let percentage = self.expenseManager.expensesByCategory[category, default: 0] / self.expenseManager.totalExpense
                if percentage > 0 {
                    PieSlice(startAngle: .degrees(angle.start), endAngle: .degrees(angle.end))
                        .fill(self.colorIncomes(for: category))
                }
            }
        }
    }
    
    func colorIncomes(for category: String) -> Color {
        switch category {
        case "Personal":
            return .expense1
        case "Food":
            return .expense2
        case "Work":
            return .expense3
        case "Health":
            return .expense4
        case "Entertainment":
            return .expense5
        case "Clothing":
            return .expense6
        case "Travel":
            return .expense7
        case "Bills":
            return .expense8
        default:
            return .expense9
        }
    }
}
