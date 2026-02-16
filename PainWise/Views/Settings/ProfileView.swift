import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAge") private var userAge: Int = 0
    @State private var editedName: String = ""
    @State private var editedAge: String = ""
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image
                    profileImageSection

                    // User Info
                    userInfoSection

                    // Stats
                    statsSection

                    // About App
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationTitle(L10n.profileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if isEditing {
                            saveProfile()
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? L10n.commonSave : L10n.commonEdit)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .onAppear {
                editedName = userName
                editedAge = userAge > 0 ? "\(userAge)" : ""
            }
        }
    }

    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appPrimary)
            }
            .overlay(
                Circle()
                    .stroke(Color.appPrimary, lineWidth: 3)
            )

            if !userName.isEmpty && !isEditing {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.profileName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray)
                    .textCase(.uppercase)

                if isEditing {
                    TextField(L10n.profileNamePlaceholder, text: $editedName)
                        .textFieldStyle(.plain)
                        .padding(16)
                        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: editedName) { _, newValue in
                            if newValue.count > 30 {
                                editedName = String(newValue.prefix(30))
                            }
                        }
                } else {
                    Text(userName.isEmpty ? L10n.profileNotSet : userName)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(userName.isEmpty ? Color.gray : (colorScheme == .dark ? .white : .black))
                }
            }

            // Age Field
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.profileAge)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray)
                    .textCase(.uppercase)

                if isEditing {
                    TextField(L10n.profileAgePlaceholder, text: $editedAge)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .padding(16)
                        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(userAge > 0 ? "\(userAge)" : L10n.profileNotSet)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(userAge > 0 ? (colorScheme == .dark ? .white : .black) : Color.gray)
                }
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.profileStats)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray)
                .textCase(.uppercase)

            HStack(spacing: 16) {
                statItem(
                    value: "\(UserDefaults.standard.integer(forKey: "totalRecords"))",
                    label: L10n.profileTotalRecords
                )

                statItem(
                    value: "\(UserDefaults.standard.integer(forKey: "streakDays"))",
                    label: L10n.profileStreakDays
                )

                statItem(
                    value: formattedFirstRecordDate(),
                    label: L10n.profileStartDate
                )
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.profileAbout)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                aboutRow(title: L10n.profileVersion, value: Self.appVersionString)
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))
                aboutRow(title: L10n.profileTerms, showChevron: true)
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))
                aboutRow(title: L10n.profilePrivacy, showChevron: true)
            }
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func aboutRow(title: String, value: String? = nil, showChevron: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(16)
    }

    // MARK: - Helpers
    private func saveProfile() {
        userName = String(editedName.prefix(30))
        if let age = Int(editedAge), (0...150).contains(age) {
            userAge = age
        }
    }

    private static let appVersionString: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (Build \(build))"
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/M"
        return f
    }()

    private func formattedFirstRecordDate() -> String {
        if let date = UserDefaults.standard.object(forKey: "firstRecordDate") as? Date {
            return Self.monthFormatter.string(from: date)
        }
        return "-"
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
