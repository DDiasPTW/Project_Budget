import SwiftUI

extension Color{
    static let income1 = Color(red: 74/255, green: 120/255, blue: 86/255)
    static let income2 = Color(red: 52/255, green: 88/255, blue: 48/255)
    static let income3 = Color(red: 30/255, green: 63/255, blue: 32/255)
    static let income4 = Color(red: 26/255, green: 31/255, blue: 22/255)
}

struct PieChartIncomeView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    
    var angles: [(start: Double, end: Double)] {
        var cumulativeAngle: Double = 0.0
        var result: [(start: Double, end: Double)] = []
        
        for category in incomeManager.incomesByCategory.keys.sorted() {
            let percentage = incomeManager.incomesByCategory[category, default: 0] / incomeManager.totalIncome
            let start = cumulativeAngle
            cumulativeAngle += 360 * percentage
            let end = cumulativeAngle
            result.append((start, end))
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(zip(incomeManager.incomesByCategory.keys.sorted(), angles)), id: \.0) { category, angle in
                let percentage = self.incomeManager.incomesByCategory[category, default: 0] / self.incomeManager.totalIncome
                if percentage > 0 {
                    PieSlice(startAngle: .degrees(angle.start), endAngle: .degrees(angle.end))
                        .fill(self.colorIncomes(for: category))
                }
            }
        }
    }
    
    func colorIncomes(for category: String) -> Color {
        switch category {
        case "Work":
            return .income1
        case "Gifts":
            return .income2
        case "Insurance":
            return .income3
        default:
            return .income4
        }
    }
}
