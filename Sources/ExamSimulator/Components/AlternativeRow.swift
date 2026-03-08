import SwiftUI
import ExamSimulatorCore

struct AlternativeRow: View {
    let alternative: Alternative
    let state: AlternativeState
    let onTap: () -> Void

    enum AlternativeState {
        case idle
        case selected
        case correct
        case incorrect
        case correctUnselected
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                letterBadge
                Text(alternative.text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if state == .correct || state == .correctUnselected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(state != .idle && state != .selected)
    }

    private var letterBadge: some View {
        Text(alternative.letter)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(letterForeground)
            .frame(width: 28, height: 28)
            .background(letterBackground)
            .clipShape(Circle())
    }

    private var background: Color {
        switch state {
        case .idle:              return Color(nsColor: .controlBackgroundColor)
        case .selected:          return Color.accentColor.opacity(0.12)
        case .correct:           return Color.green.opacity(0.12)
        case .incorrect:         return Color.red.opacity(0.12)
        case .correctUnselected: return Color.green.opacity(0.06)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:              return Color(nsColor: .separatorColor)
        case .selected:          return .accentColor
        case .correct:           return .green
        case .incorrect:         return .red
        case .correctUnselected: return .green.opacity(0.6)
        }
    }

    private var textColor: Color {
        switch state {
        case .idle, .selected:   return .primary
        case .correct, .correctUnselected: return Color.green.opacity(0.9)
        case .incorrect:         return Color.red.opacity(0.9)
        }
    }

    private var letterBackground: Color {
        switch state {
        case .idle:              return Color(nsColor: .separatorColor).opacity(0.5)
        case .selected:          return .accentColor
        case .correct:           return .green
        case .incorrect:         return .red
        case .correctUnselected: return .green.opacity(0.6)
        }
    }

    private var letterForeground: Color {
        switch state {
        case .idle: return .secondary
        default:    return .white
        }
    }
}
