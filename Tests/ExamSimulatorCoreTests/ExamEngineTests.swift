#if canImport(Testing)
import Testing
@testable import ExamSimulatorCore

@Suite("ExamEngine Filtering")
struct ExamEngineFilterTests {

    let engine = ExamEngine()

    private func makeQuestion(id: Int, simulado: Int = 1, domain: String, correct: String = "A") -> Question {
        let alternatives = ["A", "B", "C", "D"].map { letter in
            Alternative(letter: letter, text: "Option \(letter)", isCorrect: letter == correct)
        }
        return Question(
            id: id, simulado: simulado, domain: domain,
            question: "Question \(id)?",
            alternatives: alternatives,
            correctAnswer: correct,
            explanationEn: "Explanation \(id)",
            explanationPtBr: "",
            note: ""
        )
    }

    var sampleQuestions: [Question] {
        [
            makeQuestion(id: 1, simulado: 1, domain: "Domain A"),
            makeQuestion(id: 2, simulado: 1, domain: "Domain A"),
            makeQuestion(id: 3, simulado: 1, domain: "Domain B"),
            makeQuestion(id: 4, simulado: 2, domain: "Domain B"),
            makeQuestion(id: 5, simulado: 2, domain: "Domain C"),
        ]
    }

    @Test func filterAll() {
        let result = engine.filterQuestions(sampleQuestions, filter: .all)
        #expect(result.count == 5)
    }

    @Test func filterBySimuladoOne() {
        let result = engine.filterQuestions(sampleQuestions, filter: .bySimulado(1))
        #expect(result.count == 3)
    }

    @Test func filterBySimuladoTwo() {
        let result = engine.filterQuestions(sampleQuestions, filter: .bySimulado(2))
        #expect(result.count == 2)
    }

    @Test func filterByDomain() {
        let a = engine.filterQuestions(sampleQuestions, filter: .byDomain("Domain A"))
        #expect(a.count == 2)
        let c = engine.filterQuestions(sampleQuestions, filter: .byDomain("Domain C"))
        #expect(c.count == 1)
    }

    @Test func filterBookmarked() {
        let result = engine.filterQuestions(sampleQuestions, filter: .bookmarked, bookmarkedIds: [1, 3])
        #expect(result.count == 2)
        #expect(result.map { $0.id }.contains(1))
        #expect(result.map { $0.id }.contains(3))
    }

    @Test func filterIncorrectHistory() {
        let result = engine.filterQuestions(sampleQuestions, filter: .incorrectHistory, incorrectIds: [2, 5])
        #expect(result.count == 2)
    }
}

@Suite("ExamEngine Scoring")
struct ExamEngineScoringTests {

    let engine = ExamEngine()

    private func makeQ(_ id: Int, domain: String = "D") -> Question {
        let alts = ["A", "B", "C", "D"].map { Alternative(letter: $0, text: "Opt \($0)", isCorrect: $0 == "A") }
        return Question(id: id, simulado: 1, domain: domain, question: "Q\(id)?",
                        alternatives: alts, correctAnswer: "A",
                        explanationEn: "", explanationPtBr: "", note: "")
    }

    @Test func allCorrect() {
        let questions = (1...5).map { makeQ($0) }
        let config = SessionConfig(bankId: "T", mode: .exam)
        let session = ExamSession(config: config, questions: questions)
        questions.forEach { session.answers[$0.id] = "A" }
        session.endTime = Date()

        let result = engine.calculateResult(session: session, passingScore: 70, certification: "T")
        #expect(result.correctCount == 5)
        #expect(result.scorePercentage == 100.0)
        #expect(result.passed == true)
    }

    @Test func mixedResults() {
        let questions = (1...5).map { makeQ($0) }
        let config = SessionConfig(bankId: "T", mode: .exam)
        let session = ExamSession(config: config, questions: questions)
        session.answers[1] = "A"
        session.answers[2] = "A"
        session.answers[3] = "B"
        session.endTime = Date()

        let result = engine.calculateResult(session: session, passingScore: 70, certification: "T")
        #expect(result.correctCount == 2)
        #expect(result.incorrectCount == 1)
        #expect(result.skippedCount == 2)
        #expect(result.passed == false)
    }

    @Test func domainBreakdown() {
        let questions = [makeQ(1, domain: "A"), makeQ(2, domain: "A"), makeQ(3, domain: "B")]
        let config = SessionConfig(bankId: "T", mode: .exam)
        let session = ExamSession(config: config, questions: questions)
        session.answers[1] = "A"
        session.answers[2] = "B"
        session.endTime = Date()

        let result = engine.calculateResult(session: session, passingScore: 70, certification: "T")
        let domainA = result.domainScores.first { $0.domain == "A" }
        #expect(domainA?.correct == 1)
        #expect(domainA?.total == 2)
    }
}

@Suite("UserProgress")
struct UserProgressTests {

    @Test func bookmarkToggle() {
        var progress = UserProgress()
        progress.toggleBookmark(questionId: 1)
        progress.toggleBookmark(questionId: 3)
        #expect(progress.bookmarks.count == 2)
        progress.toggleBookmark(questionId: 1)
        #expect(progress.bookmarks.count == 1)
        #expect(!progress.bookmarks.contains(1))
    }

    @Test func userNotes() {
        var progress = UserProgress()
        progress.setNote("Study this", bankId: "CERT", questionId: 5)
        #expect(progress.note(bankId: "CERT", questionId: 5) == "Study this")
        #expect(progress.note(bankId: "CERT", questionId: 99) == nil)
        progress.setNote("", bankId: "CERT", questionId: 5)
        #expect(progress.note(bankId: "CERT", questionId: 5) == nil)
    }

    @Test func sessionAddsToHistory() {
        var progress = UserProgress()
        let result = SessionResult(
            id: .init(), bankId: "C", certification: "C",
            mode: .exam, date: Date(),
            totalQuestions: 2, correctCount: 1, incorrectCount: 1, skippedCount: 0,
            elapsedTime: 60, passingScore: 70, domainScores: [],
            questionResults: [
                QuestionResult(questionId: 1, selectedAnswer: "A", correctAnswer: "A", isCorrect: true, wasFlagged: false),
                QuestionResult(questionId: 2, selectedAnswer: "B", correctAnswer: "A", isCorrect: false, wasFlagged: false),
            ]
        )
        progress.addSession(result)
        #expect(progress.sessions.count == 1)
        #expect(progress.incorrectHistory.contains(2))
        #expect(!progress.incorrectHistory.contains(1))
    }
}
#endif
