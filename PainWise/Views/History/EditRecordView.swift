import SwiftUI
import SwiftData

struct EditRecordView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let record: PainRecord

    @State private var painLevel: Double
    @State private var selectedBodyParts: Set<BodyPart>
    @State private var selectedPainTypes: Set<PainType>
    @State private var note: String
    @State private var isSaving = false

    init(record: PainRecord) {
        self.record = record
        _painLevel = State(initialValue: Double(record.painLevel))
        _selectedBodyParts = State(initialValue: Set(record.bodyParts))
        _selectedPainTypes = State(initialValue: Set(record.painTypes))
        _note = State(initialValue: record.note)
    }

    private var painSeverityText: String {
        PainSeverity.fromLevel(Int(painLevel)).localizedName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pain Level Section
                    painLevelSection

                    // Body Parts Section
                    bodyPartsSection

                    // Pain Types Section
                    painTypesSection

                    // Note Section
                    noteSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationTitle(String(localized: "edit_record_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.commonCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(String(localized: "common_save"))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                    .disabled(isSaving || selectedBodyParts.isEmpty)
                }
            }
        }
    }

    // MARK: - Pain Level Section
    private var painLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L10n.quickRecordPainLevel)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(painLevel))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.appPrimary)

                        Text("/ 10")
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                    }
                }

                Spacer()

                Text(painSeverityText)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }

            PainSlider(value: $painLevel)
        }
        .padding(20)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Body Parts Section
    private var bodyPartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L10n.recordDetailBodyParts)

            FlowLayout(spacing: 8) {
                ForEach(BodyPart.allCases, id: \.self) { part in
                    bodyPartChip(part)
                }
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func bodyPartChip(_ part: BodyPart) -> some View {
        let isSelected = selectedBodyParts.contains(part)

        return Button {
            if isSelected {
                selectedBodyParts.remove(part)
            } else {
                selectedBodyParts.insert(part)
            }
        } label: {
            Text(part.localizedName)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? Color.backgroundDark : (colorScheme == .dark ? .white : Color.gray))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.appPrimary : (colorScheme == .dark ? Color(hex: "2f5e48") : Color.gray.opacity(0.1)))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pain Types Section
    private var painTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L10n.recordDetailPainTypes)

            FlowLayout(spacing: 8) {
                ForEach(PainType.allCases, id: \.self) { painType in
                    painTypeChip(painType)
                }
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func painTypeChip(_ painType: PainType) -> some View {
        let isSelected = selectedPainTypes.contains(painType)

        return Button {
            if isSelected {
                selectedPainTypes.remove(painType)
            } else {
                selectedPainTypes.insert(painType)
            }
        } label: {
            Text(painType.localizedName)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? Color.backgroundDark : (colorScheme == .dark ? .white : Color.gray))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.orange : (colorScheme == .dark ? Color(hex: "2f5e48") : Color.gray.opacity(0.1)))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(L10n.recordDetailNote)

                Spacer()

                Text("\(note.count)/200")
                    .font(.caption)
                    .foregroundStyle(note.count > 180 ? Color.orange : Color.gray)
            }

            TextEditor(text: $note)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(12)
                .background(colorScheme == .dark ? Color(hex: "1f3a2e") : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: note) { _, newValue in
                    if newValue.count > 200 {
                        note = String(newValue.prefix(200))
                    }
                }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(Color.gray)
            .textCase(.uppercase)
            .tracking(1)
    }

    // MARK: - Save Action
    private func saveChanges() {
        guard !isSaving else { return }
        isSaving = true

        // Update record properties
        record.painLevel = Int(painLevel)
        record.bodyParts = Array(selectedBodyParts)
        record.painTypes = Array(selectedPainTypes)
        record.note = note

        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save record: \(error)")
            #endif
            isSaving = false
        }
    }
}

#Preview {
    EditRecordView(record: PainRecord(
        painLevel: 6,
        bodyParts: [.lowerBack, .leftHip],
        painTypes: [.aching, .dull],
        note: "朝から腰が痛い"
    ))
    .preferredColorScheme(.dark)
    .modelContainer(for: PainRecord.self, inMemory: true)
}
