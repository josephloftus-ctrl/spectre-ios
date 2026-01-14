import SwiftUI

// MARK: - Spectre Text Field

struct SpectreTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false
    var errorMessage: String?
    var helpText: String?

    @FocusState private var isFocused: Bool

    init(
        _ title: String,
        placeholder: String = "",
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        helpText: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.helpText = helpText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpectreTheme.Spacing.xs) {
            // Label
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.spectreTextSecondary)

            // Input field
            HStack(spacing: SpectreTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(isFocused ? .spectrePrimary : .spectreTextTertiary)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.body)
                .foregroundColor(.spectreText)
                .focused($isFocused)
            }
            .padding(.horizontal, SpectreTheme.Spacing.md)
            .padding(.vertical, SpectreTheme.Spacing.sm + 4)
            .background(SpectreTheme.secondaryBackground)
            .cornerRadius(SpectreTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: SpectreTheme.Radius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)

            // Help or error text
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.spectreDestructive)
            } else if let help = helpText {
                Text(help)
                    .font(.caption)
                    .foregroundColor(.spectreTextTertiary)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return .spectreDestructive
        } else if isFocused {
            return .spectrePrimary
        } else {
            return SpectreTheme.border
        }
    }
}

// MARK: - Spectre Search Field

struct SpectreSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: SpectreTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.spectreTextTertiary)

            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.spectreText)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.spectreTextTertiary)
                }
            }
        }
        .padding(.horizontal, SpectreTheme.Spacing.md)
        .padding(.vertical, SpectreTheme.Spacing.sm + 2)
        .background(SpectreTheme.secondaryBackground)
        .cornerRadius(SpectreTheme.Radius.full)
        .overlay(
            RoundedRectangle(cornerRadius: SpectreTheme.Radius.full)
                .stroke(isFocused ? SpectreTheme.primary : SpectreTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.spectreBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: SpectreTheme.Spacing.lg) {
                SpectreSearchField(text: .constant(""))

                SpectreTextField(
                    "Email",
                    placeholder: "Enter your email",
                    text: .constant(""),
                    icon: "envelope"
                )

                SpectreTextField(
                    "Password",
                    placeholder: "Enter password",
                    text: .constant(""),
                    icon: "lock",
                    isSecure: true,
                    helpText: "Must be at least 8 characters"
                )

                SpectreTextField(
                    "Username",
                    placeholder: "Enter username",
                    text: .constant("test"),
                    icon: "person",
                    errorMessage: "Username already taken"
                )
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
