import SwiftUI
import ExamSimulatorCore

// MARK: - Container

/// AI chat sidebar panel embedded alongside the question in study/review screens.
/// Use `.id(question.id)` at the call site to reset when the question changes.
struct AIAssistantView: View {
    @StateObject private var viewModel: AIAssistantViewModel
    @EnvironmentObject private var loc: LocalizationService

    init(aiService: AIStudyAssistantService,
         question: Question,
         selectedAnswer: String?,
         languageIsEnglish: Bool) {
        _viewModel = StateObject(
            wrappedValue: AIAssistantViewModel(
                aiService: aiService,
                question: question,
                selectedAnswer: selectedAnswer,
                languageIsEnglish: languageIsEnglish
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messageList
            if let err = viewModel.error {
                errorBanner(err)
            }
            if viewModel.messages.isEmpty == false && !viewModel.isLoading {
                suggestionChips
                Divider()
            }
            Divider()
            inputRow
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .task { await viewModel.loadInitialExplanation() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
            Text(loc.t("ai.title"))
                .font(.subheadline.weight(.semibold))
            Text("· \(loc.t("ai.poweredBy"))")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty && viewModel.isLoading {
                        loadingBubble
                            .id("loading")
                    }
                    ForEach(viewModel.messages) { msg in
                        messageBubble(msg)
                            .id(msg.id)
                    }
                    if !viewModel.messages.isEmpty && viewModel.isLoading {
                        loadingBubble
                            .id("loading")
                    }
                }
                .padding(12)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation {
                    proxy.scrollTo("loading", anchor: .bottom)
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) {
                if viewModel.isLoading {
                    withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                }
            }
        }
    }

    private var loadingBubble: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption2)
                .foregroundStyle(.purple)
            DotsLoadingView()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        if msg.role == .assistant {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.purple)
                    .padding(.top, 2)
                Text(msg.content)
                    .font(.callout)
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            HStack {
                Spacer(minLength: 20)
                Text(msg.content)
                    .font(.callout)
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Suggestion chips

    private var suggestionKeys: [String] {
        ["ai.suggestion.deepen",
         "ai.suggestion.example",
         "ai.suggestion.whyWrong",
         "ai.suggestion.realWorld",
         "ai.suggestion.simplify"]
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(suggestionKeys, id: \.self) { key in
                    Button(loc.t(key)) {
                        viewModel.quickSend(loc.t(key))
                    }
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.purple.opacity(0.2), lineWidth: 1))
                    .disabled(viewModel.isLoading)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            Button { viewModel.dismissError() } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.08))
    }

    // MARK: - Input row

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField(loc.t("ai.placeholder"), text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .font(.callout)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .onSubmit { Task { await viewModel.send() } }

            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundStyle(canSend ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .help(loc.t("ai.send"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isLoading
    }
}

// MARK: - Dots loading animation

private struct DotsLoadingView: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .frame(width: 5, height: 5)
                    .foregroundStyle(Color.purple.opacity(phase == i ? 1.0 : 0.3))
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        // .task is cancelled automatically when the view disappears — no timer leak.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 350_000_000)
                phase = (phase + 1) % 3
            }
        }
    }
}
