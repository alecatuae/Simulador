import SwiftUI
import ExamSimulatorCore

struct DomainStatRow: View {
    let domain: String
    let correct: Int
    let total: Int

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(domain)
                    .font(.subheadline)
                    .lineLimit(1)
                    .help(domain)
                Spacer()
                Text("\(correct)/\(total)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(percentage.formattedPercent)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(barColor)
                    .frame(width: 54, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * percentage, height: 6)
                        .animation(.easeOut(duration: 0.6), value: percentage)
                }
            }
            .frame(height: 6)
        }
    }

    private var barColor: Color {
        if percentage >= 0.8 { return .green }
        if percentage >= 0.6 { return .orange }
        return .red
    }
}

struct DomainStatRow_DomainScore: View {
    let score: DomainScore

    var body: some View {
        DomainStatRow(domain: score.domain, correct: score.correct, total: score.total)
    }
}
