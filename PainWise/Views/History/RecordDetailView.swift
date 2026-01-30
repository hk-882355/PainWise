import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let record: PainRecord

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    private var borderColor: Color {
        switch record.painLevel {
        case 0...2: return .painMild
        case 3...5: return .painModerate
        case 6...8: return .painSevere
        default: return .painExtreme
        }
    }

    private var severityText: String {
        switch record.painLevel {
        case 0...2: return L10n.painSeverityMild
        case 3...5: return L10n.painSeverityModerate
        case 6...8: return L10n.painSeveritySevere
        default: return L10n.painSeverityExtreme
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pain Level Card
                    painLevelSection

                    // Date & Time
                    dateTimeSection

                    // Body Parts
                    if !record.bodyParts.isEmpty {
                        bodyPartsSection
                    }

                    // Pain Types
                    if !record.painTypes.isEmpty {
                        painTypesSection
                    }

                    // Weather Data
                    if let weather = record.weatherData {
                        weatherSection(weather)
                    }

                    // Health Data
                    if let health = record.healthData {
                        healthSection(health)
                    }

                    // Note
                    if !record.note.isEmpty {
                        noteSection
                    }

                    // Delete Button
                    deleteButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationTitle(L10n.recordDetailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditSheet = true }) {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditRecordView(record: record)
            }
            .alert(L10n.recordDeleteConfirmTitle, isPresented: $showDeleteAlert) {
                Button(L10n.commonCancel, role: .cancel) {}
                Button(L10n.commonDelete, role: .destructive) {
                    deleteRecord()
                }
            } message: {
                Text(L10n.recordDeleteConfirmMessage)
            }
        }
    }

    // MARK: - Pain Level Section
    private var painLevelSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(borderColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(borderColor, lineWidth: 4)
                    .frame(width: 120, height: 120)

                VStack(spacing: 4) {
                    Text("\(record.painLevel)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(borderColor)

                    Text("/ 10")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }

            Text(severityText)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(borderColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(borderColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        HStack(spacing: 16) {
            detailItem(
                icon: "calendar",
                iconColor: .blue,
                title: L10n.recordDetailDate,
                value: formatDate(record.timestamp)
            )

            detailItem(
                icon: "clock",
                iconColor: .orange,
                title: L10n.recordDetailTime,
                value: formatTime(record.timestamp)
            )
        }
    }

    // MARK: - Body Parts Section
    private var bodyPartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.recordDetailBodyParts)

            FlowLayout(spacing: 8) {
                ForEach(record.bodyParts, id: \.self) { part in
                    Text(part.localizedName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appPrimary.opacity(0.1))
                        .foregroundStyle(Color.appPrimary)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Pain Types Section
    private var painTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.recordDetailPainTypes)

            FlowLayout(spacing: 8) {
                ForEach(record.painTypes, id: \.self) { painType in
                    Text(painType.localizedName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .foregroundStyle(Color.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Weather Section
    private func weatherSection(_ weather: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.recordDetailWeather)

            HStack(spacing: 16) {
                detailItem(
                    icon: "gauge",
                    iconColor: .green,
                    title: L10n.forecastCardPressure,
                    value: String(format: "%.0f hPa", weather.pressure)
                )

                detailItem(
                    icon: "thermometer",
                    iconColor: .red,
                    title: L10n.forecastTemperature,
                    value: String(format: "%.1f°C", weather.temperature)
                )

                detailItem(
                    icon: "humidity",
                    iconColor: .blue,
                    title: L10n.recordDetailHumidity,
                    value: String(format: "%.0f%%", weather.humidity)
                )
            }
        }
    }

    // MARK: - Health Section
    private func healthSection(_ health: HealthSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.recordDetailHealth)

            HStack(spacing: 16) {
                if let steps = health.stepCount {
                    detailItem(
                        icon: "figure.walk",
                        iconColor: .green,
                        title: L10n.settingsStepCount,
                        value: "\(Int(steps))"
                    )
                }

                if let sleep = health.sleepDuration {
                    detailItem(
                        icon: "bed.double.fill",
                        iconColor: .indigo,
                        title: L10n.settingsSleepData,
                        value: String(format: "%.1fh", sleep)
                    )
                }

                if let hr = health.heartRate {
                    detailItem(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: L10n.settingsHeartRate,
                        value: "\(Int(hr)) bpm"
                    )
                }
            }
        }
    }

    // Compatibility wrapper for older data
    private func healthSectionCompatible(_ health: HealthSnapshot) -> some View {
        healthSection(health)
    }

    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.recordDetailNote)

            Text(record.note)
                .font(.body)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            HStack {
                Image(systemName: "trash")
                Text(L10n.recordDeleteButton)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 16)
    }

    // MARK: - Helpers
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(Color.gray)
            .textCase(.uppercase)
            .tracking(1)
    }

    private func detailItem(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.gray)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func deleteRecord() {
        modelContext.delete(record)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete record: \(error)")
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing

                self.size.width = max(self.size.width, x)
            }

            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    RecordDetailView(record: PainRecord(
        painLevel: 7,
        bodyParts: [.head, .neck, .leftShoulder],
        painTypes: [.throbbing, .aching],
        note: "朝から頭痛がひどい。天気が悪くなる前兆かもしれない。"
    ))
    .preferredColorScheme(.dark)
}
