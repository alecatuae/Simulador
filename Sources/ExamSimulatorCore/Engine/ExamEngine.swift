import Foundation

public final class ExamEngine {
    public init() {}

    public func filterQuestions(
        _ questions: [Question],
        filter: QuestionFilter,
        bookmarkedIds: Set<Int> = [],
        incorrectIds: Set<Int> = []
    ) -> [Question] {
        switch filter {
        case .all:
            return questions
        case .byDomain(let domain):
            return questions.filter { $0.domain == domain }
        case .incorrectHistory:
            return questions.filter { incorrectIds.contains($0.id) }
        case .bookmarked:
            return questions.filter { bookmarkedIds.contains($0.id) }
        }
    }

    public func buildSession(
        config: SessionConfig,
        questions: [Question],
        bookmarkedIds: Set<Int> = [],
        incorrectIds: Set<Int> = []
    ) -> ExamSession {
        // Step 1 — Scope: keep only questions matching the selected filter.
        var filtered = filterQuestions(
            questions,
            filter: config.filter,
            bookmarkedIds: bookmarkedIds,
            incorrectIds: incorrectIds
        )

        // Step 2 — Order: shuffle BEFORE applying the limit so that
        //   prefix(N) is a truly random sample from the full filtered pool,
        //   not just the first N questions in original file order.
        if config.randomizeQuestions {
            filtered.shuffle()
        }

        // Step 3 — Limit: take the first N after the optional shuffle.
        //   nil  → use all available (no truncation).
        //   N≥filtered.count → ignored, all questions used.
        if let limit = config.questionLimit, limit < filtered.count {
            filtered = Array(filtered.prefix(limit))
        }

        // Step 4 — Answer order: optionally reshuffle alternative letters.
        if config.randomizeAnswers {
            filtered = filtered.map { question -> Question in
                let shuffled = question.alternatives.shuffled()
                let letters = ["A", "B", "C", "D", "E"]
                let reassigned = shuffled.enumerated().map { idx, alt in
                    Alternative(letter: letters[idx], text: alt.text, isCorrect: alt.isCorrect)
                }
                let newCorrect = reassigned.first(where: { $0.isCorrect })?.letter ?? question.correctAnswer
                return Question(
                    id: question.id,
                    domain: question.domain,
                    question: question.question,
                    alternatives: reassigned,
                    correctAnswer: newCorrect,
                    explanationEn: question.explanationEn,
                    explanationPtBr: question.explanationPtBr,
                    note: question.note
                )
            }
        }

        return ExamSession(config: config, questions: filtered)
    }

    public func calculateResult(
        session: ExamSession,
        passingScore: Double,
        certification: String
    ) -> SessionResult {
        var domainMap: [String: (correct: Int, total: Int)] = [:]
        var questionResults: [QuestionResult] = []
        var correctCount = 0

        for question in session.questions {
            let selected = session.answers[question.id]
            let isCorrect = selected == question.correctAnswer

            if isCorrect { correctCount += 1 }

            domainMap[question.domain, default: (0, 0)].total += 1
            if isCorrect { domainMap[question.domain]!.correct += 1 }

            questionResults.append(QuestionResult(
                questionId: question.id,
                selectedAnswer: selected,
                correctAnswer: question.correctAnswer,
                isCorrect: isCorrect,
                wasFlagged: session.flaggedIds.contains(question.id)
            ))
        }

        let domainScores = domainMap
            .map { domain, counts in DomainScore(domain: domain, correct: counts.correct, total: counts.total) }
            .sorted { $0.domain < $1.domain }

        let answeredCount = session.answers.count
        let incorrectCount = answeredCount - correctCount
        let skippedCount = session.questions.count - answeredCount
        let elapsed = (session.endTime ?? Date()).timeIntervalSince(session.startTime)

        return SessionResult(
            id: UUID(),
            bankId: session.config.bankId,
            certification: certification,
            mode: session.config.mode,
            date: session.startTime,
            totalQuestions: session.questions.count,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            skippedCount: skippedCount,
            elapsedTime: elapsed,
            passingScore: passingScore,
            domainScores: domainScores,
            questionResults: questionResults
        )
    }
}
