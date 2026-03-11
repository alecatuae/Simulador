# Metadata — QA JSON Files

Documentação do bloco `metadata` e da estrutura de questões presentes nos arquivos de banco de questões (`*_QA.json`).

---

## Estrutura do arquivo

```json
{
  "metadata": { ... },
  "questions": [ ... ]
}
```

---

## Bloco `metadata`

```json
{
  "metadata": {
    "title": "NVIDIA NCA-AIIO — Guia de Estudo: Perguntas e Respostas",
    "certification": "NVIDIA Certified Associate — AI Infrastructure and Operations (NCA-AIIO)",
    "source": "Practice Exams — NVIDIA AI Infrastructure NCA-AIIO 2026 (Udemy)",
    "format": "Perguntas e alternativas em inglês. Explicações traduzidas para português (pt-br).",
    "passing_score_percent": 80,
    "total_questions": 130,
    "domains": [
      { "name": "Introduction to AI", "count": 18 },
      { "name": "AI Infrastructure",  "count": 73 },
      { "name": "AI Operations",      "count": 39 }
    ]
  }
}
```

---

## Campos do `metadata`

| Campo                   | Tipo     | Obrigatório | Padrão | Descrição                                                        |
|-------------------------|----------|:-----------:|:------:|------------------------------------------------------------------|
| `title`                 | string   | ✓           | —      | Título completo do documento de estudo                           |
| `certification`         | string   | ✓           | —      | Nome oficial da certificação (usado como ID único do banco)      |
| `source`                | string   | ✓           | —      | Origem das questões                                              |
| `format`                | string   | ✓           | —      | Descrição do idioma das perguntas e explicações                  |
| `passing_score_percent` | number   |             | `70`   | Nota mínima para aprovação (0–100). Editável via Browse Questions |
| `total_questions`       | integer  | ✓           | —      | Total de questões no arquivo                                     |
| `domains`               | array    | ✓           | —      | Lista dos domínios da certificação com contagem de questões      |

> **Retrocompatibilidade**: `passing_score_percent` é opcional — arquivos sem o campo usam `70.0` automaticamente.

---

### Como `passing_score_percent` afeta o simulador

- Copiado para `SessionConfig.passingScorePercent` ao iniciar qualquer sessão.
- Usado pelo `ExamEngine` para calcular Pass/Fail no `SessionResult`.
- Editável em **Browse Questions → Bank Settings bar** e salvo em Application Support.
- Exibido na tela de configuração de sessão: "Aprovação: 80%".

---

## Domínios (NCA-AIIO)

| Domínio               | Questões | % do Total |
|-----------------------|:--------:|:----------:|
| Introduction to AI    |    18    |   13,8%    |
| AI Infrastructure     |    73    |   56,2%    |
| AI Operations         |    39    |   30,0%    |
| **Total**             |  **130** | **100%**   |

---

## Estrutura de cada questão (`questions[]`)

```json
{
  "id": 1,
  "domain": "AI Operations",
  "question": "Texto da pergunta em inglês",
  "alternatives": [
    { "letter": "A", "text": "Alternativa A", "is_correct": false },
    { "letter": "B", "text": "Alternativa B", "is_correct": true  },
    { "letter": "C", "text": "Alternativa C", "is_correct": false },
    { "letter": "D", "text": "Alternativa D", "is_correct": false }
  ],
  "correct_answer": "B",
  "explanation_en":   "Explicação em inglês.",
  "explanation_ptbr": "Explicação traduzida em português.",
  "note": ""
}
```

### Campos de cada questão

| Campo              | Tipo    | Obrigatório | Descrição                                              |
|--------------------|---------|:-----------:|--------------------------------------------------------|
| `id`               | integer | ✓           | Número sequencial único no banco                       |
| `domain`           | string  | ✓           | Domínio da certificação                                |
| `question`         | string  | ✓           | Texto da pergunta                                      |
| `alternatives`     | array   | ✓           | Lista de alternativas (normalmente A–D ou A–E)         |
| `correct_answer`   | string  | ✓           | Letra da alternativa correta (`"A"` – `"E"`)           |
| `explanation_en`   | string  | ✓           | Explicação em inglês                                   |
| `explanation_ptbr` | string  | ✓           | Explicação em português (fallback para EN se vazio)    |
| `note`             | string  |             | Campo livre para anotações (vazio por padrão)          |

---

## Arquivos disponíveis

| Arquivo                 | Certificação                   | Questões | Passing |
|-------------------------|--------------------------------|:--------:|:-------:|
| `NCA-AIIO_QA.json`      | NVIDIA NCA-AIIO                | 130      | 80%     |
| `IT-Fundamentals_QA.json` | IT & AI Fundamentals Associate | 20       | 70%     |

- **Localização**: `Sources/ExamSimulator/Resources/QAs/`
- **Encoding**: UTF-8
- **Edições do usuário** salvas em: `~/Library/Application Support/ExamSimulator/QAs/`
