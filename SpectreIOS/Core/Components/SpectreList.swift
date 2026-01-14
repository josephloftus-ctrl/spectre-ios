import SwiftUI

// MARK: - Spectre List Row

struct SpectreListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: SpectreTheme.Spacing.md) {
                leading

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.spectreText)
                        .lineLimit(1)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.spectreTextSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                trailing

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.spectreTextTertiary)
                }
            }
            .padding(.horizontal, SpectreTheme.Spacing.md)
            .padding(.vertical, SpectreTheme.Spacing.sm + 4)
            .background(SpectreTheme.cardBackground)
        }
        .buttonStyle(SpectreListRowPressStyle())
        .disabled(action == nil)
    }
}

struct SpectreListRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? SpectreTheme.secondaryBackground : SpectreTheme.cardBackground)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Spectre List Section

struct SpectreListSection<Content: View>: View {
    let title: String?
    let content: Content

    init(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpectreTheme.Spacing.sm) {
            if let title = title {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.spectreTextTertiary)
                    .padding(.horizontal, SpectreTheme.Spacing.md)
            }

            VStack(spacing: 1) {
                content
            }
            .background(SpectreTheme.border)
            .cornerRadius(SpectreTheme.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: SpectreTheme.Radius.lg)
                    .stroke(SpectreTheme.borderSubtle, lineWidth: 1)
            )
        }
    }
}

// MARK: - Status Row Icon

struct SpectreStatusIcon: View {
    let status: Status
    let size: CGFloat

    enum Status {
        case success
        case warning
        case error
        case info
        case pending

        var color: Color {
            switch self {
            case .success: return .spectreSuccess
            case .warning: return .spectreWarning
            case .error: return .spectreDestructive
            case .info: return .spectreInfo
            case .pending: return .spectreTextTertiary
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .pending: return "clock.fill"
            }
        }
    }

    init(_ status: Status, size: CGFloat = 24) {
        self.status = status
        self.size = size
    }

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: size * 0.7))
            .foregroundColor(status.color)
            .frame(width: size, height: size)
    }
}

// MARK: - Avatar/Icon Container

struct SpectreAvatar: View {
    let icon: String?
    let initials: String?
    let size: CGFloat
    let backgroundColor: Color

    init(
        icon: String? = nil,
        initials: String? = nil,
        size: CGFloat = 40,
        backgroundColor: Color = .spectrePrimary
    ) {
        self.icon = icon
        self.initials = initials
        self.size = size
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.2))

            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size * 0.45))
                    .foregroundColor(backgroundColor)
            } else if let initials = initials {
                Text(initials.prefix(2).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(backgroundColor)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.spectreBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: SpectreTheme.Spacing.lg) {
                SpectreListSection("Sites") {
                    SpectreListRow(
                        title: "Main Office",
                        subtitle: "24 devices",
                        leading: { SpectreAvatar(icon: "building.2.fill") },
                        trailing: { SpectreStatusIcon(.success) }
                    ) {
                        print("Tapped Main Office")
                    }

                    SpectreListRow(
                        title: "Warehouse A",
                        subtitle: "156 devices",
                        leading: { SpectreAvatar(initials: "WA", backgroundColor: .spectreWarning) },
                        trailing: { SpectreStatusIcon(.warning) }
                    ) {
                        print("Tapped Warehouse")
                    }

                    SpectreListRow(
                        title: "Remote Site",
                        subtitle: "Offline",
                        leading: { SpectreAvatar(icon: "wifi.slash", backgroundColor: .spectreDestructive) },
                        trailing: { SpectreStatusIcon(.error) }
                    ) {
                        print("Tapped Remote")
                    }
                }

                SpectreListSection("Settings") {
                    SpectreListRow(
                        title: "Notifications",
                        leading: {
                            SpectreAvatar(icon: "bell.fill", size: 32, backgroundColor: .spectreInfo)
                        }
                    ) {}

                    SpectreListRow(
                        title: "Account",
                        leading: {
                            SpectreAvatar(icon: "person.fill", size: 32)
                        }
                    ) {}
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
