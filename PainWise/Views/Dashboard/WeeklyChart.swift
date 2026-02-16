import SwiftUI
import Charts

struct WeeklyChartSection: View {
    @Environment(\.colorScheme) var colorScheme
    let records: [PainRecord]

    @State private var selectedPeriod: String = "全期間"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("過去7日間の推移")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Menu {
                    Button("今週") { selectedPeriod = "今週" }
                    Button("今月") { selectedPeriod = "今月" }
                    Button("全期間") { selectedPeriod = "全期間" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }

            // Chart
            chartView
                .frame(height: 160)
                .padding(20)
                .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private var filteredRecords: [PainRecord] {
        let calendar = Calendar.current
        let now = Date()

        let cutoffDate: Date?
        switch selectedPeriod {
        case "今週":
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now)
        case "今月":
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now)
        default: // "全期間"
            cutoffDate = nil
        }

        guard let cutoff = cutoffDate else { return records }
        return records.filter { $0.timestamp >= cutoff }
    }

    @ViewBuilder
    private var chartView: some View {
        if filteredRecords.isEmpty {
            // Demo data when no records
            let demoData = generateDemoData()
            Chart(demoData) { item in
                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Pain", item.level)
                )
                .foregroundStyle(Color.appPrimary)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", item.day),
                    y: .value("Pain", item.level)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.2), Color.appPrimary.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Day", item.day),
                    y: .value("Pain", item.level)
                )
                .foregroundStyle(item.isToday ? Color.appPrimary : (colorScheme == .dark ? Color.surfaceDark : Color.gray.opacity(0.3)))
                .symbolSize(item.isToday ? 100 : 40)
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption2)
                                .foregroundStyle(day == "今日" ? Color.appPrimary : Color.textSecondary)
                                .fontWeight(day == "今日" ? .bold : .medium)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 5, 10]) { _ in
                    AxisGridLine()
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))
                }
            }
            .chartYScale(domain: 0...10)
        } else {
            // Real data
            let chartData = filteredRecords.enumerated().map { index, record in
                ChartDataPoint(
                    day: dayLabel(for: index),
                    level: record.painLevel,
                    isToday: index == 0
                )
            }.reversed()

            Chart(Array(chartData)) { item in
                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Pain", item.level)
                )
                .foregroundStyle(Color.appPrimary)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", item.day),
                    y: .value("Pain", item.level)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.2), Color.appPrimary.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...10)
        }
    }

    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter
    }()

    private func dayLabel(for index: Int) -> String {
        guard index < filteredRecords.count else { return "\(index)" }
        let date = filteredRecords[index].timestamp
        if Calendar.current.isDateInToday(date) {
            return "今日"
        }
        return Self.dayOfWeekFormatter.string(from: date)
    }

    private func generateDemoData() -> [ChartDataPoint] {
        let days = ["月", "火", "水", "木", "金", "土", "今日"]
        let levels = [3, 4, 6, 5, 4, 3, 2]
        return days.enumerated().map { index, day in
            ChartDataPoint(day: day, level: levels[index], isToday: day == "今日")
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id: String
    let day: String
    let level: Int
    let isToday: Bool

    init(day: String, level: Int, isToday: Bool) {
        self.id = day
        self.day = day
        self.level = level
        self.isToday = isToday
    }
}

#Preview {
    WeeklyChartSection(records: [])
        .padding()
        .background(Color.backgroundDark)
        .preferredColorScheme(.dark)
}
