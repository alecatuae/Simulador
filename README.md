# Exam Simulator

A modular, configuration-driven certification exam simulator for macOS built with Swift and SwiftUI.

Modeled after VCE Exam Simulator behavior, designed as a reusable platform for multiple certifications.

---

## Features

- **Study Mode** — immediate answer feedback with bilingual explanations
- **Exam Mode** — timed simulation with question navigation and flagging
- **Review Mode** — post-exam review with filter by correct/incorrect/flagged
- **Progress Tracking** — session history, bookmarks, user notes, incorrect history
- **Multi-language UI** — English and Portuguese out of the box; add new languages by dropping a JSON file
- **Multiple Exam Banks** — add new certifications by dropping a JSON file in `Resources/QAs/`
- **AI Integration** — protocol-ready architecture (OpenAI in Phase 2)

---

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (for Swift toolchain and SDKs)
- Swift 5.9+
- Visual Studio Code with the **Swift** extension (optional, for editing)

---

## Getting Started

### 1. Install Prerequisites

```bash
xcode-select --install
```

Verify:

```bash
swift --version
```

### 2. Clone / Open the Project

```bash
cd "/path/to/Simulador"
```

### 3. Build

```bash
swift build
```

### 4. Run

```bash
swift run ExamSimulator
```

### 5. Test

```bash
swift test
```

---

## Project Structure

```
Sources/
├── ExamSimulatorCore/          # Pure Swift library — no UI dependencies
│   ├── Models/                 # Question, ExamBank, SessionResult, UserProgress, AppConfig
│   ├── Services/
│   │   ├── AI/                 # AIProvider protocol + MockAIProvider
│   │   ├── Localization/       # LocalizationService
│   │   └── Configuration/     # AppConfigService
│   ├── Repositories/
│   │   ├── ExamBank/           # Loads and validates QA JSON files
│   │   └── Progress/           # Persists UserProgress to Application Support
│   ├── Engine/                 # ExamEngine: filtering, shuffling, scoring
│   └── Utilities/              # Extensions (TimeInterval, Date, Double)
│
└── ExamSimulator/              # macOS SwiftUI app target
    ├── App/                    # @main entry point, AppDependencies
    ├── Views/                  # DashboardView, ExamView, StudyView, ResultView, ReviewView
    ├── ViewModels/             # DashboardViewModel, ExamViewModel, StudyViewModel, ReviewViewModel
    ├── Components/             # AlternativeRow, TimerView, QuestionNavigatorView, DomainStatRow
    └── Resources/
        ├── QAs/                # Exam bank JSON files
        ├── Languages/          # UI language pack JSON files
        └── AppConfig.json      # App configuration

Tests/
└── ExamSimulatorCoreTests/     # Unit tests for Core library
```

---

## Adding a New Exam Bank

1. Create a JSON file following the schema in `Doc/metadata-json.md`
2. Drop it into `Sources/ExamSimulator/Resources/QAs/`
3. Rebuild — the app will discover it automatically at startup

---

## Adding a New UI Language

1. Copy `Sources/ExamSimulator/Resources/Languages/en-us.json`
2. Translate all values (keep the keys unchanged)
3. Save as `{language-code}.json` in the same directory (e.g., `es-es.json`)
4. Rebuild — the language will appear in settings automatically

---

## Configuration

Edit `Sources/ExamSimulator/Resources/AppConfig.json` to change:

- Default language
- Exam timer (minutes)
- Passing score threshold (%)
- Randomize questions / answers
- Feature flags (disable Study Mode, Exam Mode, etc.)
- AI provider settings (for Phase 2)
- Storage directory

---

## AI Integration (Phase 2)

The `AIProvider` protocol is implemented as `MockAIProvider` in Phase 1.
To enable real AI assistance:

1. Set `"aiAssistant": true` and `"enabled": true` in `AppConfig.json`
2. Set the environment variable: `export OPENAI_API_KEY="your-key-here"`
3. Implement `OpenAIProvider` conforming to `AIProvider`

---

## Architecture

- **MVVM** — Views bind to `@StateObject` ViewModels; no business logic in Views
- **Dependency Injection** — `AppDependencies` composes all services at startup and passes them via `@EnvironmentObject`
- **Platform Separation** — `ExamSimulatorCore` is a pure Swift library with no SwiftUI imports; safe to reuse in iOS

---

## Data Persistence

Progress is saved to:

```
~/Library/Application Support/ExamSimulator/progress.json
```

The location is configurable via `AppConfig.json → storage.progressDirectory`.

---

## Current Exam Banks

| File | Certification | Questions |
|------|--------------|-----------|
| `NCA-AIIO_QA.json` | NVIDIA Certified Associate — AI Infrastructure and Operations | 130 |
