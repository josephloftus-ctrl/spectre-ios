import SwiftUI

// MARK: - Steady Text Field

struct SteadyTextField: View {
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
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.steadyTextSecondary)

            HStack(spacing: SteadyTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(isFocused ? .steadyPrimary : .steadyTextTertiary)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.body)
                .foregroundColor(.steadyText)
                .focused($isFocused)
            }
            .padding(.horizontal, SteadyTheme.Spacing.md)
            .padding(.vertical, SteadyTheme.Spacing.sm + 4)
            .background(SteadyTheme.secondaryBackground)
            .cornerRadius(SteadyTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: SteadyTheme.Radius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.steadyDestructive)
            } else if let help = helpText {
                Text(help)
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil {
            return .steadyDestructive
        } else if isFocused {
            return .steadyPrimary
        } else {
            return SteadyTheme.border
        }
    }
}

// MARK: - Steady Search Field

struct SteadySearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: SteadyTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.steadyTextTertiary)

            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.steadyText)
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
                        .foregroundColor(.steadyTextTertiary)
                }
            }
        }
        .padding(.horizontal, SteadyTheme.Spacing.md)
        .padding(.vertical, SteadyTheme.Spacing.sm + 2)
        .background(SteadyTheme.secondaryBackground)
        .cornerRadius(SteadyTheme.Radius.full)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.full)
                .stroke(isFocused ? SteadyTheme.primary : SteadyTheme.border, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.steadyBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: SteadyTheme.Spacing.lg) {
                SteadySearchField(text: .constant(""))

                SteadyTextField(
                    "Email",
                    placeholder: "Enter your email",
                    text: .constant(""),
                    icon: "envelope"
                )

                SteadyTextField(
                    "Password",
                    placeholder: "Enter password",
                    text: .constant(""),
                    icon: "lock",
                    isSecure: true,
                    helpText: "Must be at least 8 characters"
                )
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
