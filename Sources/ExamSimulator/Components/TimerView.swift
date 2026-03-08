import SwiftUI
import ExamSimulatorCore

struct TimerView: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval

    private var progress: Double {
        guard totalTime > 0 else { return 1 }
        return timeRemaining / totalTime
    }

    private var isWarning: Bool { timeRemaining < 300 && timeRemaining > 0 }
    private var isCritical: Bool { timeRemaining < 60 && timeRemaining > 0 }
    private var isExpired: Bool { timeRemaining <= 0 }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.subheadline)
                .foregroundStyle(timerColor)
                .symbolEffect(.pulse, isActive: isWarning)

            Text(timeRemaining.formattedClock)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(timerColor)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(timerColor.opacity(0.1))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: isCritical)
    }

    private var timerColor: Color {
        if isExpired || isCritical { return .red }
        if isWarning { return .orange }
        return .secondary
    }
}
