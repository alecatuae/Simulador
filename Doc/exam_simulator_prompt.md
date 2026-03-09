# Modular Certification Exam Simulator — System Prompt

You are a senior Apple platform engineer specialized in macOS/iOS
development with Swift, SwiftUI, app architecture, local persistence,
modular software design, and certification exam simulator systems
similar to VCE Exam Simulator.

Your task is to design and generate a complete Swift project for macOS
first, with architecture prepared for future iOS compatibility, that
implements a certification exam training application modeled after VCE
Exam Simulator behavior.

------------------------------------------------------------------------

# Core Premise

This application must be designed as an **extremely modular,
parameterized, and extensible platform**.

The system must not be hardcoded for a single certification exam, a
single language, or a single content model instance. It must be able to
scale as a reusable exam simulator platform.

------------------------------------------------------------------------

# Primary Goal

Build a desktop-first exam simulator for macOS using Swift and SwiftUI
that allows candidates to:

-   Practice certification questions
-   Review answers
-   Study explanations
-   Track progress
-   Simulate timed exams
-   Use AI assistance for learning support

The application must rely on **local configurable datasets and modular
architecture**.

------------------------------------------------------------------------

# Development Constraints

-   Programming language: **Swift**
-   UI framework: **SwiftUI**
-   Architecture: **MVVM or Clean MVVM**
-   Minimum target: **macOS 14 (Sonoma)**
-   IDE: **Visual Studio Code (VSCode)** with Swift extension
-   Build system: **Swift Package Manager (SPM)** — see Build System note below
-   Comments in code: **English (en-us)**
-   README and technical documentation: **English (en-us)**
-   The project must run locally on macOS
-   Prefer native Apple frameworks and minimal dependencies

------------------------------------------------------------------------

# Build System Decision

## Confirmed Approach: SPM Executable + Library Targets

A pure SPM setup is used for maximum VSCode compatibility:

-   `ExamSimulator` — `.executableTarget` with `@main App` entry point
-   `ExamSimulatorCore` — `.target` (library) with all pure logic
-   `ExamSimulatorCoreTests` — `.testTarget`

Build and run commands:

    swift build
    swift run ExamSimulator
    swift test

> Note: The app runs as an unsigned macOS process without sandbox
> restrictions, which is acceptable for local development. Future
> production packaging can use Xcode with code signing.

------------------------------------------------------------------------

# Strategic Architecture Requirement

The application must be designed as a **configuration-driven platform**.

This means:

-   Multiple exam banks can be added
-   Multiple languages can be added
-   AI providers can be swapped
-   Features can be enabled/disabled via configuration

No code modification should be required when adding new content.

------------------------------------------------------------------------

# Modular Content Architecture

## Exam Banks

The system must support multiple exam datasets.

Resources are bundled inside the `ExamSimulator` SPM target:

    Sources/ExamSimulator/Resources/QAs/

Examples:

    QAs/NCA-AIIO_QA.json
    QAs/CCNA_QA.json
    QAs/Kubernetes_QA.json

The app must:

-   Scan the directory at startup via `Bundle.module`
-   Validate datasets
-   Build a certification catalog
-   Allow users to choose which exam to study

------------------------------------------------------------------------

## Language Packs

All UI string translations are external JSON files bundled with the app.

Directory:

    Sources/ExamSimulator/Resources/Languages/

Examples:

    Languages/en-us.json
    Languages/pt-br.json
    Languages/es-es.json

**Important distinction:** Language Packs only govern UI strings (buttons,
labels, menus). Question content (text, alternatives, explanations) is
embedded directly in each question's JSON and is independent of the
Language Pack system. Questions/alternatives are always in English (source
language); explanations are provided in both English and Portuguese per
question.

Requirements:

-   UI must use translation keys via `LocalizationService`
-   Missing translations fall back to default language
-   Runtime language switching supported

------------------------------------------------------------------------

# Configuration Layer

File location:

    Sources/ExamSimulator/Resources/AppConfig.json

Schema:

```json
{
  "appVersion": "1.0.0",
  "defaultLanguage": "en-us",
  "fallbackLanguage": "en-us",
  "examDefaults": {
    "timerMinutes": 90,
    "passingScorePercent": 70.0,
    "randomizeQuestions": true,
    "randomizeAnswers": false
  },
  "aiProvider": {
    "enabled": false,
    "provider": "openai",
    "baseURL": "https://api.openai.com/v1",
    "model": "gpt-4o-mini",
    "apiKeyEnvVar": "OPENAI_API_KEY"
  },
  "features": {
    "studyMode": true,
    "examMode": true,
    "reviewMode": true,
    "progressTracking": true,
    "aiAssistant": false,
    "bookmarks": true
  },
  "storage": {
    "progressDirectory": "~/Library/Application Support/ExamSimulator"
  }
}
```

------------------------------------------------------------------------

# Data Model

## Source of Truth

The canonical data format is defined by `NCA-AIIO_QA.json`.

## File-level structure

```json
{
  "metadata": { ... },
  "questions": [ ... ]
}
```

## Metadata block

```json
{
  "metadata": {
    "title": "...",
    "certification": "...",
    "source": "...",
    "format": "...",
    "passing_score_percent": 80,
    "total_questions": 130,
    "simulados": [
      { "number": 1, "range": "1-65",   "questions": 65 },
      { "number": 2, "range": "66-130", "questions": 65 }
    ],
    "domains": [
      { "name": "Introduction to AI", "count": 18 },
      { "name": "AI Infrastructure",  "count": 73 },
      { "name": "AI Operations",      "count": 39 }
    ]
  }
}
```

### `passing_score_percent` — nota mínima do banco

| Aspecto | Detalhe |
|---|---|
| Tipo | `number` (0–100) |
| Obrigatório | Não — padrão `70.0` se ausente |
| Editável em runtime | Sim — via **Browse Questions → Bank Settings bar** |
| Persistência | Salvo em App Support quando o usuário altera e pressiona **Save** |
| Propagação | Copiado para `SessionConfig.passingScorePercent` ao iniciar qualquer sessão |
| Uso | Passado ao `ExamEngine.calculateResult()` para determinar Pass/Fail |
| Visibilidade na UI | Exibido na tela de configuração de sessão: "Aprovação: 80%" |

> **Nota**: O valor em `AppConfig.examDefaults.passingScorePercent` deixou de ser usado
> para sessões iniciadas pelo usuário. Esse campo global permanece como fallback
> apenas para sessões construídas programaticamente sem um banco associado.

## Question structure

```json
{
  "id": 1,
  "simulado": 1,
  "domain": "AI Operations",
  "question": "Question text in English",
  "alternatives": [
    { "letter": "A", "text": "...", "is_correct": false },
    { "letter": "B", "text": "...", "is_correct": true  },
    { "letter": "C", "text": "...", "is_correct": false },
    { "letter": "D", "text": "...", "is_correct": false }
  ],
  "correct_answer": "B",
  "explanation_en":   "Explanation in English.",
  "explanation_ptbr": "Explicação em português.",
  "note": ""
}
```

## Data Model Decisions

-   `correct_answer` (string) is the **canonical source of truth** for
    answer comparison; `is_correct` (bool) on alternatives is auxiliary
    and used only for display rendering
-   `note` in the JSON is **read-only dataset content** — user
    annotations are stored separately in `UserProgress.userNotes`
-   The `simulado` field is a **session filter**, not a separate entity.
    Users may choose: all questions, Simulado 1, Simulado 2, or by domain

------------------------------------------------------------------------

# Product Vision

The application should resemble professional exam simulators like **VCE
Exam Simulator**.

Core modes:

-   **Study Mode** — immediate feedback after each answer with explanations
-   **Exam Mode** — timed session with no feedback until submission
-   **Review Mode** — post-exam review of all questions with answers and explanations

Features:

-   timed sessions
-   question navigator
-   flagged questions
-   score reports
-   domain statistics
-   progress tracking
-   AI study assistant (Phase 2)

------------------------------------------------------------------------

# AI Integration

**MVP (Phase 1):** Architecture only — protocol stub, no real API calls.

Protocol:

    AIProvider protocol
    MockAIProvider (stub returning placeholder text)
    AIStudyAssistantService

The "Ask AI" button appears in Study Mode but is disabled unless an
`AIProvider` with `enabled: true` is configured.

**Phase 2:** Implement `OpenAIProvider` using `AppConfig.aiProvider`.

Requirements:

-   API keys never hardcoded — read from environment variable specified in config
-   Configuration driven
-   Optional feature controlled by `features.aiAssistant` flag
-   Allow future providers via `AIProvider` protocol

------------------------------------------------------------------------

# Required Application Features

## Question Loading

-   Load all JSON datasets from `Resources/QAs/` via `Bundle.module`
-   Validate schema on load
-   Cache parsed banks in memory
-   `ExamBankRepository` receives `Bundle` via dependency injection (testable)

------------------------------------------------------------------------

## Dashboard

Show:

-   List of available exam banks (sidebar)
-   Selected bank: certification title, question count, domain distribution
-   Last session summary (date, score, pass/fail)

Actions:

-   Start Exam (full timed simulation)
-   Study Mode (question by question with explanations)
-   Review Incorrect (filter to incorrect history)
-   Browse Questions (list + inline editor for all questions in the bank)

------------------------------------------------------------------------

## Session Configuration

When starting a session, the user selects:

-   **Question scope:** All | Simulado 1 | Simulado 2 | By Domain |
    Bookmarked | Incorrect History
-   **Mode:** Exam (timed, no feedback) | Study (immediate feedback)
-   **Order:** Random (shuffled) | Sequential (original order)
-   **Question count:** 1 … N (defaults to all available for the
    selected scope; user can reduce via Stepper)

`QuestionFilter` enum:

    case all
    case bySimulado(Int)
    case byDomain(String)
    case incorrectHistory
    case bookmarked

`SessionConfig` fields relevant to the above:

    randomizeQuestions: Bool   // true = random, false = sequential
    questionLimit: Int?        // nil = use all; otherwise take first N
                               // (after optional shuffle)

The sheet shows a live preview counter: "N of M questions".
A "Use all (M)" shortcut resets the limit to nil.

------------------------------------------------------------------------

## Browse Questions

`BrowseQuestionsView` opens as a full-window sheet from the Dashboard
action button "Browse Questions". It provides a searchable, editable
list of every question in the selected exam bank.

### Layout

-   **Toolbar (top bar)**
    -   Back button (with discard-changes confirmation when dirty)
    -   Bank certification + question count
    -   "Unsaved changes" indicator (orange, visible when dirty)
    -   Domain picker (filter list to one domain or All)
    -   Search field (filters by question text, domain, or ID)
    -   "Save" button (green, visible only when there are unsaved edits)

-   **Bank Settings bar** (between toolbar and question list)
    -   Displays and edits `passing_score_percent` via Stepper (step 5, range 1–100)
    -   Changes are tracked as dirty edits and saved with the "Save" button

-   **Question list** — each row shows:
    -   `#id`  ·  Simulado badge  ·  Domain  ·  First ~2 lines of question text
    -   Pencil icon on right to indicate tappable row
    -   Orange left-border stripe when the row has unsaved edits

-   Tapping a row opens `QuestionEditorSheet` (modal sheet).

### QuestionEditorSheet

Fields exposed for editing:

| Field | Control |
|---|---|
| Domain | TextField + dropdown menu (pick existing or type new) |
| Simulado | Stepper |
| Question text | TextEditor |
| Alternative A–E text | TextField per alternative |
| Correct answer | Circle button (radio-style) per alternative |
| Explanation EN | TextEditor |
| Explanation PT-BR | TextEditor |
| Note | TextField |

The editor toolbar has **Cancel** (discards draft) and **Done**
(commits to in-memory bank). Saving from the editor does **not**
immediately write to disk — it only marks the bank as dirty.

Pressing **Save** in the browse toolbar persists the full bank to
`~/Library/Application Support/ExamSimulator/QAs/<filename>.json`.

### Persistence

-   Modified banks are saved to **Application Support**, mirroring
    the original bundle filename.
-   `ExamBankRepository.loadAll()` prefers the Application Support
    version when present, falling back to the bundle.
-   `ExamBankRepository.save(_ bank:)` writes the full `ExamBank`
    (encoded as pretty JSON) and updates the in-memory cache.
-   Returning to the Dashboard triggers `loadData()` so the sidebar
    and detail reflect the updated bank immediately.

------------------------------------------------------------------------

## Exam Engine

Responsibilities:

-   `filterQuestions(_:filter:bookmarkedIds:incorrectIds:)` — applies filter
-   `buildSession(config:questions:bookmarkedIds:incorrectIds:)` —
    shuffles (if `randomizeQuestions`), applies `questionLimit`, then
    optionally randomizes alternative letters
-   `calculateResult(session:passingScore:certification:)` — computes scores

Session state is managed by `ExamViewModel` (timer, current index,
selected answers, flagged IDs).

------------------------------------------------------------------------

## Scoring

Provide:

-   total score and percentage
-   correct / incorrect / skipped counts
-   domain performance breakdown
-   elapsed time
-   pass/fail indicator (vs `passingScorePercent` from `SessionConfig`, sourced from bank metadata)

------------------------------------------------------------------------

## Study Workflow

Each question in Study Mode displays after answering:

-   selected answer (highlighted correct/incorrect)
-   correct answer
-   explanation in English
-   explanation in Portuguese (toggle)
-   bookmark feature
-   AI explanation button (disabled in MVP)

------------------------------------------------------------------------

# Progress Tracking

Persisted to `~/Library/Application Support/ExamSimulator/progress.json`:

```
UserProgress
├── sessions: [SessionResult]       — completed exam/study sessions
├── bookmarks: Set<Int>             — bookmarked question IDs
├── userNotes: [String: String]     — "bankId:questionId" → user note text
├── incorrectHistory: Set<Int>      — question IDs answered incorrectly
└── totalStudyTime: TimeInterval
```

Persistence: **JSON files** via `ProgressRepository` (not SwiftData).
Language preference: **UserDefaults** (key: `app.language`).

------------------------------------------------------------------------

# Two Localization Systems (Distinct)

## System 1 — Language Packs (UI strings)

File: `Resources/Languages/en-us.json`

Controls all interface text: buttons, labels, titles, messages.
Managed by `LocalizationService`. User-selectable at runtime.

## System 2 — Question Content (embedded in QA files)

Fields `explanation_en` and `explanation_ptbr` in each question.
These are NOT managed by Language Packs. The UI shows the explanation
matching the current language when available, otherwise falls back to English.

------------------------------------------------------------------------

# Project Structure

```
ExamSimulator/                          ← repo root
├── Package.swift
├── README.md
├── Sources/
│   ├── ExamSimulatorCore/              ← pure library, no UI dependencies
│   │   ├── Models/
│   │   │   ├── Question.swift
│   │   │   ├── ExamBank.swift
│   │   │   ├── ExamSession.swift
│   │   │   ├── SessionResult.swift
│   │   │   ├── UserProgress.swift
│   │   │   └── AppConfig.swift
│   │   ├── Services/
│   │   │   ├── AI/
│   │   │   │   ├── AIProvider.swift
│   │   │   │   └── MockAIProvider.swift
│   │   │   ├── Localization/
│   │   │   │   └── LocalizationService.swift
│   │   │   └── Configuration/
│   │   │       └── AppConfigService.swift
│   │   ├── Repositories/
│   │   │   ├── ExamBank/
│   │   │   │   └── ExamBankRepository.swift
│   │   │   └── Progress/
│   │   │       └── ProgressRepository.swift
│   │   ├── Engine/
│   │   │   └── ExamEngine.swift
│   │   └── Utilities/
│   │       └── Extensions.swift
│   └── ExamSimulator/                  ← executable app target
│       ├── App/
│       │   ├── ExamSimulatorApp.swift
│       │   └── AppDependencies.swift
│       ├── Views/
│       │   ├── DashboardView.swift
│       │   ├── StudyView.swift
│       │   ├── ExamView.swift
│       │   ├── ReviewView.swift
│       │   ├── ResultView.swift
│       │   └── BrowseQuestionsView.swift
│       ├── ViewModels/
│       │   ├── DashboardViewModel.swift
│       │   ├── StudyViewModel.swift
│       │   ├── ExamViewModel.swift
│       │   ├── ReviewViewModel.swift
│       │   └── BrowseQuestionsViewModel.swift
│       ├── Components/
│       │   ├── QuestionCard.swift
│       │   ├── AlternativeRow.swift
│       │   ├── TimerView.swift
│       │   ├── DomainStatRow.swift
│       │   └── QuestionNavigatorView.swift
│       └── Resources/
│           ├── QAs/
│           │   └── NCA-AIIO_QA.json
│           ├── Languages/
│           │   ├── en-us.json
│           │   └── pt-br.json
│           └── AppConfig.json
├── Tests/
│   └── ExamSimulatorCoreTests/
│       ├── ExamBankTests.swift
│       └── ExamEngineTests.swift
└── Doc/
    ├── exam_simulator_prompt.md       ← this file
    └── metadata-json.md
```

------------------------------------------------------------------------

# Development Environment (macOS + VSCode)

## Required: Xcode

Provides Apple SDKs, Swift toolchain, and build tools.

## Command Line Tools

    xcode-select --install

Verify:

    swift --version
    xcodebuild -version

## VSCode Extension

Install: **Swift** (by Swift Server Work Group)

------------------------------------------------------------------------

# Build Commands

    swift build                    # compile
    swift run ExamSimulator        # build and run the app
    swift test                     # run all tests

------------------------------------------------------------------------

# Deliverables

The generated project must include:

1.  Full Swift source code
2.  README.md with build instructions
3.  Architecture documentation (this file)
4.  Folder structure
5.  Example datasets (`NCA-AIIO_QA.json`)
6.  Language files (`en-us.json`, `pt-br.json`)
7.  AI integration stubs
8.  Testing strategy with example tests

------------------------------------------------------------------------

# Non-Negotiable Modularity Rules

-   Adding a new certification exam requires only dropping a valid
    JSON file into `Resources/QAs/`
-   Adding a new UI language requires only dropping a valid JSON
    file into `Resources/Languages/`
-   Changing AI provider settings requires configuration changes only
-   The UI must consume abstractions and services, never directly read
    raw files
-   The code must avoid business logic tied specifically to NCA-AIIO
-   The app must be designed as a platform kernel plus plug-in-like
    content packs
-   All exam, language, and AI behavior must be discoverable and
    configurable at runtime whenever feasible

------------------------------------------------------------------------

# MVP Scope (Phase 1)

In scope:

-   Exam bank loading and catalog
-   Dashboard with bank selection
-   Study Mode (immediate feedback, bookmarks)
-   Exam Mode (timed, navigation, flags)
-   Result screen (score, domain breakdown)
-   Review Mode (post-exam question review)
-   Progress persistence (JSON files)
-   Language Packs: en-us, pt-br
-   AIProvider protocol + MockAIProvider stub
-   Browse Questions with inline question editor

Out of scope (Phase 2):

-   Real OpenAI API calls
-   Historical progress charts
-   In-app QA file importer (drag-and-drop new bank files)
-   iOS companion app
-   App Store distribution / code signing
