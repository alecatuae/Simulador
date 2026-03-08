import SwiftUI
import ExamSimulatorCore

struct QuestionNavigatorView: View {
    let questions: [Question]
    let answeredIds: Set<Int>
    let flaggedIds: Set<Int>
    let currentIndex: Int
    let onSelect: (Int) -> Void

    private let columns = Array(repeating: GridItem(.fixed(32), spacing: 4), count: 10)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(questions.indices, id: \.self) { index in
                    let question = questions[index]
                    let isAnswered = answeredIds.contains(question.id)
                    let isFlagged = flaggedIds.contains(question.id)
                    let isCurrent = index == currentIndex

                    Button {
                        onSelect(index)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(cellBackground(isCurrent: isCurrent, isAnswered: isAnswered, isFlagged: isFlagged))
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(cellForeground(isCurrent: isCurrent, isAnswered: isAnswered))
                            if isFlagged {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 10, y: -10)
                            }
                        }
                        .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(maxHeight: 200)
    }

    private func cellBackground(isCurrent: Bool, isAnswered: Bool, isFlagged: Bool) -> Color {
        if isCurrent     { return .accentColor }
        if isFlagged     { return Color.orange.opacity(0.15) }
        if isAnswered    { return Color(nsColor: .controlAccentColor).opacity(0.2) }
        return Color(nsColor: .controlColor)
    }

    private func cellForeground(isCurrent: Bool, isAnswered: Bool) -> Color {
        if isCurrent  { return .white }
        if isAnswered { return .accentColor }
        return .secondary
    }
}
