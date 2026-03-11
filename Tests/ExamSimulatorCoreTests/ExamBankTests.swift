#if canImport(Testing)
import Testing
@testable import ExamSimulatorCore

@Suite("ExamBank Decoding")
struct ExamBankTests {

    static let sampleJSON = """
    {
      "metadata": {
        "title": "Test Certification",
        "certification": "TEST-001",
        "source": "Unit Test",
        "format": "English questions",
        "total_questions": 2,
        "domains": [
          { "name": "Domain A", "count": 2 }
        ]
      },
      "questions": [
        {
          "id": 1,
          "domain": "Domain A",
          "question": "What is 2+2?",
          "alternatives": [
            { "letter": "A", "text": "3", "is_correct": false },
            { "letter": "B", "text": "4", "is_correct": true },
            { "letter": "C", "text": "5", "is_correct": false },
            { "letter": "D", "text": "6", "is_correct": false }
          ],
          "correct_answer": "B",
          "explanation_en": "Basic arithmetic: 2+2=4.",
          "explanation_ptbr": "Aritmética básica: 2+2=4.",
          "note": ""
        }
      ]
    }
    """.data(using: .utf8)!

    @Test func decodeMetadata() throws {
        let bank = try JSONDecoder().decode(ExamBank.self, from: Self.sampleJSON)
        #expect(bank.metadata.certification == "TEST-001")
        #expect(bank.metadata.totalQuestions == 2)
        #expect(bank.questions.count == 1)
    }

    @Test func decodeAlternatives() throws {
        let bank = try JSONDecoder().decode(ExamBank.self, from: Self.sampleJSON)
        let q1 = bank.questions[0]
        #expect(q1.correctAnswer == "B")
        #expect(q1.alternatives.count == 4)
        #expect(q1.alternatives[1].isCorrect == true)
        #expect(q1.explanationPtBr == "Aritmética básica: 2+2=4.")
    }

    @Test func explanationFallbackToEnglish() {
        let alt = Alternative(letter: "A", text: "Answer", isCorrect: true)
        let question = Question(
            id: 1, domain: "Test",
            question: "Q?",
            alternatives: [alt],
            correctAnswer: "A",
            explanationEn: "English explanation",
            explanationPtBr: "",
            note: ""
        )
        #expect(question.explanation(for: "en-us") == "English explanation")
        #expect(question.explanation(for: "pt-br") == "English explanation")
    }

    @Test func explanationPtBrReturned() {
        let alt = Alternative(letter: "A", text: "Answer", isCorrect: true)
        let question = Question(
            id: 1, domain: "Test",
            question: "Q?",
            alternatives: [alt],
            correctAnswer: "A",
            explanationEn: "English",
            explanationPtBr: "Português",
            note: ""
        )
        #expect(question.explanation(for: "pt-br") == "Português")
        #expect(question.explanation(for: "en-us") == "English")
    }
}
#endif
