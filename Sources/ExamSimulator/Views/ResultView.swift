import SwiftUI
import ExamSimulatorCore

struct ResultView: View {
    @StateObject var viewModel: ReviewViewModel
    let result: SessionResult
    let bank: ExamBank

    @EnvironmentObject var loc: LocalizationService
    @Environment(\.dismiss) var dismiss

    @State private var scoreProgress: Double = 0
    @State private var showReview = false

    var body: some View {
        if showReview {
            ReviewView(viewModel: viewModel)
        } else {
            resultContent
        }
    }

    // MARK: - Main layout

    private var resultContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                heroSection
                statsGrid
                scoreBarSection
                domainSection
                actionButtons
            }
            .padding(40)
        }
        .frame(minWidth: 740, minHeight: 580)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                scoreProgress = result.scorePercentage / 100
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            scoreRing
            passFail
            sessionMeta
        }
    }

    private var scoreRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(nsColor: .separatorColor), lineWidth: 12)
                .frame(width: 164, height: 164)

            // Threshold arc (faint orange band at passing point)
            Circle()
                .trim(from: max(0, result.passingScore / 100 - 0.008),
                      to: min(1, result.passingScore / 100 + 0.008))
                .stroke(Color.orange, lineWidth: 14)
                .frame(width: 164, height: 164)
                .rotationEffect(.degrees(-90))

            // Score arc
            Circle()
                .trim(from: 0, to: scoreProgress)
                .stroke(
                    result.passed ? Color.green : Color.red,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 164, height: 164)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.2), value: scoreProgress)

            // Center label
            VStack(spacing: 3) {
                Text(result.scorePercentage.formattedPercent)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(result.passed ? .green : .red)
                    .monospacedDigit()
                Text("\(result.correctCount)/\(result.totalQuestions)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var passFail: some View {
        HStack(spacing: 8) {
            Image(systemName: result.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.title3)
                .foregroundStyle(result.passed ? .green : .red)
            Text(result.passed ? loc.t("result.congratulations") : loc.t("result.keepStudying"))
                .font(.title3.weight(.semibold))
        }
    }

    private var sessionMeta: some View {
        HStack(spacing: 6) {
            Text(result.certification)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("·").foregroundStyle(.tertiary)
            modeBadge
            Text("·").foregroundStyle(.tertiary)
            Text(result.date.formattedShort)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var modeBadge: some View {
        let (label, color, icon): (String, Color, String) = {
            switch result.mode {
            case .exam:   return (loc.t("result.mode.exam"),   .blue,   "timer")
            case .study:  return (loc.t("result.mode.study"),  .purple, "book.open")
            case .review: return (loc.t("result.mode.review"), .gray,   "magnifyingglass")
            }
        }()
        return Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        HStack(spacing: 0) {
            statCard(
                icon: "checkmark.circle.fill",
                value: "\(result.correctCount)",
                label: loc.t("result.correct"),
                color: .green
            )
            Divider().frame(height: 64)
            statCard(
                icon: "xmark.circle.fill",
                value: "\(result.incorrectCount)",
                label: loc.t("result.incorrect"),
                color: .red
            )
            Divider().frame(height: 64)
            statCard(
                icon: "minus.circle.fill",
                value: "\(result.skippedCount)",
                label: loc.t("result.skipped"),
                color: Color(nsColor: .secondaryLabelColor)
            )
            Divider().frame(height: 64)
            statCard(
                icon: "clock.fill",
                value: result.elapsedTime.formattedElapsed,
                label: loc.t("result.timeElapsed"),
                color: Color.accentColor
            )
        }
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Score vs required bar

    private var scoreBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.t("result.scoreVsRequired"))
                    .font(.headline)
                Spacer()
                Group {
                    Text(result.scorePercentage.formattedPercent)
                        .foregroundStyle(result.passed ? .green : .red)
                    Text(" · ")
                        .foregroundStyle(.secondary)
                    Text(loc.t("result.required") + ": \(Int(result.passingScore))%")
                        .foregroundStyle(.orange)
                }
                .font(.subheadline.monospacedDigit())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 12)

                    // Score fill
                    RoundedRectangle(cornerRadius: 5)
                        .fill(result.passed ? Color.green : Color.red)
                        .frame(width: geo.size.width * scoreProgress, height: 12)
                        .animation(.easeOut(duration: 1.2), value: scoreProgress)

                    // Threshold marker
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.orange)
                        .frame(width: 3, height: 22)
                        .offset(x: geo.size.width * (result.passingScore / 100) - 1.5,
                                y: -5)
                }
            }
            .frame(height: 12)

            // Legend
            HStack {
                legendDot(color: result.passed ? .green : .red,
                          label: "\(loc.t("result.score")): \(result.scorePercentage.formattedPercent)")
                Spacer()
                legendDot(color: .orange,
                          label: "\(loc.t("result.passingScore")): \(Int(result.passingScore))%",
                          square: true)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func legendDot(color: Color, label: String, square: Bool = false) -> some View {
        HStack(spacing: 6) {
            if square {
                Rectangle()
                    .fill(color)
                    .frame(width: 10, height: 3)
                    .cornerRadius(1.5)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Domain breakdown

    private var domainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t("result.domainBreakdown"))
                .font(.headline)

            VStack(spacing: 10) {
                // Sorted worst first so the user immediately sees where to focus
                ForEach(result.domainScores.sorted(by: { $0.percentage < $1.percentage })) { domain in
                    DomainStatRow(
                        domain: domain.domain,
                        correct: domain.correct,
                        total: domain.total
                    )
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(loc.t("result.backToDashboard")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button(loc.t("result.reviewAnswers")) {
                showReview = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
