import SwiftUI
import SwiftData
import FirebaseCrashlytics

struct HistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PainRecord.timestamp, order: .reverse) private var records: [PainRecord]

    // Services
    private let pdfService = PDFReportService.shared
    @ObservedObject private var analysisService = AnalysisService.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @AppStorage("userName") private var userName: String = ""

    // PDF States
    @State private var isGeneratingPDF = false
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var selectedPeriod: PeriodFilter = .thisWeek
    @State private var selectedIntensityFilter: IntensityFilter = .all
    @State private var selectedRecord: PainRecord?
    @State private var showPeriodPicker = false
    @State private var showIntensityPicker = false
    @State private var showPremium = false

    enum PeriodFilter: CaseIterable {
        case thisWeek, thisMonth, threeMonths, all

        var displayName: String {
            switch self {
            case .thisWeek: return L10n.historyPeriodThisWeek
            case .thisMonth: return String(localized: "history_period_this_month")
            case .threeMonths: return String(localized: "history_period_3_months")
            case .all: return String(localized: "history_period_all")
            }
        }

        var daysBack: Int? {
            switch self {
            case .thisWeek: return 7
            case .thisMonth: return 30
            case .threeMonths: return 90
            case .all: return nil
            }
        }
    }

    enum IntensityFilter: CaseIterable {
        case all, high, medium, low

        var displayName: String {
            switch self {
            case .all: return L10n.historyFilterAll
            case .high: return L10n.historyFilterHigh
            case .medium: return L10n.historyFilterMedium
            case .low: return L10n.historyFilterLow
            }
        }
    }

    var filteredRecords: [PainRecord] {
        let now = Date()
        let calendar = Calendar.current

        return records.filter { record in
            // Search filter (uses debounced text)
            let matchesSearch = debouncedSearchText.isEmpty ||
                record.bodyParts.contains { $0.rawValue.contains(debouncedSearchText) } ||
                record.note.contains(debouncedSearchText)

            // Period filter
            let matchesPeriod: Bool
            if let daysBack = selectedPeriod.daysBack {
                let cutoff = calendar.date(byAdding: .day, value: -daysBack, to: now) ?? now
                matchesPeriod = record.timestamp >= cutoff
            } else {
                matchesPeriod = true
            }

            // Intensity filter
            let matchesIntensity: Bool
            switch selectedIntensityFilter {
            case .all: matchesIntensity = true
            case .high: matchesIntensity = record.painLevel >= 7
            case .medium: matchesIntensity = record.painLevel >= 4 && record.painLevel < 7
            case .low: matchesIntensity = record.painLevel >= 1 && record.painLevel < 4
            }

            return matchesSearch && matchesPeriod && matchesIntensity
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // PDF Button
                VStack(spacing: 12) {
                    if !storeKit.isPremium {
                        PremiumGateCard(
                            title: "PDFエクスポートはプレミアム",
                            message: "履歴データをPDFで出力できます。",
                            buttonTitle: "プレミアムを見る",
                            onUpgrade: { showPremium = true }
                        )
                    }

                    pdfButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 8)

                // Search & Filter
                searchAndFilterSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Records List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredRecords.isEmpty {
                            emptyState
                        } else {
                            recordsList
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarHidden(true)
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
            .sheet(isPresented: $showPeriodPicker) {
                PeriodPickerView(selectedPeriod: $selectedPeriod)
                    .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showIntensityPicker) {
                IntensityPickerView(selectedFilter: $selectedIntensityFilter)
                    .presentationDetents([.height(300)])
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        .onChange(of: searchText) { _, newValue in
            searchDebounceTask?.cancel()
            if newValue.isEmpty {
                debouncedSearchText = ""
            } else {
                searchDebounceTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    debouncedSearchText = newValue
                }
            }
        }
    }

    // MARK: - Period Picker View
    struct PeriodPickerView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.colorScheme) var colorScheme
        @Binding var selectedPeriod: PeriodFilter

        var body: some View {
            NavigationStack {
                List {
                    ForEach(PeriodFilter.allCases, id: \.self) { period in
                        Button {
                            selectedPeriod = period
                            dismiss()
                        } label: {
                            HStack {
                                Text(period.displayName)
                                Spacer()
                                if selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                .navigationTitle(L10n.historyFilterPeriod)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: - Intensity Picker View
    struct IntensityPickerView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.colorScheme) var colorScheme
        @Binding var selectedFilter: IntensityFilter

        var body: some View {
            NavigationStack {
                List {
                    ForEach(IntensityFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.displayName)
                                Spacer()
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                .navigationTitle(L10n.historyFilterIntensity)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Spacer()

            Text(L10n.historyTitle)
                .font(.headline)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 16)
    }

    // MARK: - PDF Button
    private var pdfButton: some View {
        Button(action: { storeKit.isPremium ? generatePDF() : (showPremium = true) }) {
            HStack(spacing: 8) {
                if isGeneratingPDF {
                    ProgressView()
                        .tint(Color.backgroundDark)
                } else {
                    Image(systemName: "doc.text")
                        .font(.title3)
                }
                Text(isGeneratingPDF ? L10n.historyGeneratingPdf : L10n.historyCreatePdf)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.backgroundDark)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(records.isEmpty ? Color.gray : Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.appPrimary.opacity(0.15), radius: 20)
        }
        .disabled(records.isEmpty || isGeneratingPDF)
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
        .overlay(alignment: .trailing) {
            if !storeKit.isPremium {
                PremiumBadge(text: "Premium")
                    .padding(.trailing, 16)
            }
        }
    }

    private func generatePDF() {
        isGeneratingPDF = true

        Task {
            // Analyze records first to get correlations
            await analysisService.analyzeRecords(records)

            // Generate PDF
            if let data = pdfService.generateReport(
                records: records,
                correlations: analysisService.correlations,
                userName: userName.isEmpty ? "患者様" : userName
            ) {
                pdfData = data
                showShareSheet = true
            }
            isGeneratingPDF = false
        }
    }

    // MARK: - Search & Filter
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)

                TextField(L10n.historySearchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        showPeriodPicker = true
                    } label: {
                        filterChipLabel(title: "\(L10n.historyFilterPeriod): \(selectedPeriod.displayName)", isActive: selectedPeriod != .thisWeek)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showIntensityPicker = true
                    } label: {
                        filterChipLabel(title: "\(L10n.historyFilterIntensity): \(selectedIntensityFilter.displayName)", isActive: selectedIntensityFilter != .all)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func filterChipLabel(title: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .foregroundStyle(isActive ? Color.appPrimary : (colorScheme == .dark ? .white : .black))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isActive ? Color.appPrimary.opacity(0.1) : (colorScheme == .dark ? Color.surfaceDark : Color.white))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isActive ? Color.appPrimary : (colorScheme == .dark ? Color(hex: "2e5c46") : Color.gray.opacity(0.2)), lineWidth: 1)
        )
    }

    @State private var recordToDelete: PainRecord?
    @State private var showDeleteConfirm = false

    // MARK: - Records List
    private var recordsList: some View {
        ForEach(filteredRecords) { record in
            Button {
                selectedRecord = record
            } label: {
                RecordCard(record: record)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    recordToDelete = record
                    showDeleteConfirm = true
                } label: {
                    Label(L10n.commonDelete, systemImage: "trash")
                }
            }
        }
        .alert(L10n.recordDeleteConfirmTitle, isPresented: $showDeleteConfirm) {
            Button(L10n.commonCancel, role: .cancel) {}
            Button(L10n.commonDelete, role: .destructive) {
                if let record = recordToDelete {
                    modelContext.delete(record)
                    do {
                        try modelContext.save()
                    } catch {
                        #if DEBUG
                        print("Failed to delete record: \(error)")
                        #endif
                        Crashlytics.crashlytics().record(error: error)
                    }
                }
            }
        } message: {
            Text(L10n.recordDeleteConfirmMessage)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.textSecondary)

            Text(L10n.historyNoRecords)
                .font(.headline)
                .foregroundStyle(Color.textSecondary)

            Text(L10n.historyNoRecordsHint)
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }
}

// MARK: - Record Card
struct RecordCard: View {
    @Environment(\.colorScheme) var colorScheme
    let record: PainRecord

    private var borderColor: Color {
        record.painLevelColor
    }

    private var severityText: String {
        record.painLevelText
    }

    var body: some View {
        HStack(spacing: 16) {
            // Pain Level Badge
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(borderColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text("\(record.painLevel)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(borderColor)
                }

                Text(severityText)
                    .font(.system(size: 10))
                    .fontWeight(.bold)
                    .foregroundStyle(borderColor)
            }
            .frame(width: 48)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(formatDate(record.timestamp))
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Spacer()

                    Text(formatTime(record.timestamp))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                // Body Parts Tags
                HStack(spacing: 8) {
                    ForEach(record.bodyParts.prefix(3), id: \.self) { part in
                        Text(part.localizedName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorScheme == .dark ? Color(hex: "1f4031") : Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                // Note
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 0)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(borderColor)
                .frame(width: 4)
                .padding(.vertical, 8)
        }
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility_record_card_label \(formatDate(record.timestamp))"))
        .accessibilityValue(String(localized: "accessibility_record_card_value \(record.painLevel) \(record.bodyParts.map { $0.localizedName }.joined(separator: ", "))"))
        .accessibilityHint(String(localized: "accessibility_tap_to_view_details"))
    }

    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        return formatter
    }()

    private static let cardTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        Self.cardDateFormatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        Self.cardTimeFormatter.string(from: date)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}
