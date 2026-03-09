# Metadata — QA JSON Files

Documentação do bloco `metadata` presente nos arquivos de banco de questões (`*_QA.json`).

---

## Estrutura

```json
{
  "metadata": {
    "title": "NVIDIA NCA-AIIO — Guia de Estudo: Perguntas e Respostas",
    "certification": "NVIDIA Certified Associate — AI Infrastructure and Operations (NCA-AIIO)",
    "source": "Practice Exams — NVIDIA AI Infrastructure NCA-AIIO 2026 (Udemy)",
    "format": "Perguntas e alternativas em inglês (idioma original). Explicações traduzidas para português (pt-br).",
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

---

## Campos

| Campo                   | Tipo     | Obrigatório | Padrão | Descrição                                                        |
|-------------------------|----------|:-----------:|:------:|------------------------------------------------------------------|
| `title`                 | string   | ✓           | —      | Título completo do documento de estudo                           |
| `certification`         | string   | ✓           | —      | Nome oficial da certificação (usado como ID único do banco)      |
| `source`                | string   | ✓           | —      | Origem das questões                                              |
| `format`                | string   | ✓           | —      | Descrição do idioma das perguntas e explicações                  |
| `passing_score_percent` | number   |             | `70`   | Nota mínima para aprovação (0–100). Editável via Browse Questions |
| `total_questions`       | integer  | ✓           | —      | Total de questões no arquivo                                     |
| `simulados`             | array    | ✓           | —      | Lista dos simulados com número, faixa de questões e quantidade   |
| `domains`               | array    | ✓           | —      | Lista dos domínios da certificação com contagem de questões      |

> **Retrocompatibilidade**: `passing_score_percent` é opcional. Arquivos que não incluam o campo assumem o valor padrão `70.0` automaticamente.

---

### Como `passing_score_percent` afeta o simulador

- O valor é lido no momento do carregamento do banco.
- Ao iniciar um Exam ou Study, o valor é copiado para `SessionConfig.passingScorePercent`.
- O `ExamEngine` usa esse valor para calcular o `SessionResult` (passed/failed).
- O usuário pode alterar `passing_score_percent` diretamente em **Browse Questions** (barra de configurações do banco). A alteração é salva em `~/Library/Application Support/ExamSimulator/QAs/`.
- A tela de configuração de sessão exibe o valor como informação: "Aprovação: 80%".

---

## Simulados

| Simulado | Faixa de Questões | Quantidade |
|:--------:|:-----------------:|:----------:|
| 1        | Q1 – Q65          | 65         |
| 2        | Q66 – Q130        | 65         |

---

## Domínios

| Domínio               | Questões | % do Total |
|-----------------------|:--------:|:----------:|
| Introduction to AI    |    18    |   13,8%    |
| AI Infrastructure     |    73    |   56,2%    |
| AI Operations         |    39    |   30,0%    |
| **Total**             |  **130** | **100%**   |

---

## Estrutura Completa de uma Questão (`questions[]`)

```json
{
  "id": 1,
  "simulado": 1,
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

| Campo              | Tipo    | Descrição                                              |
|--------------------|---------|--------------------------------------------------------|
| `id`               | integer | Número sequencial global da questão (1–130)            |
| `simulado`         | integer | Simulado de origem: `1` ou `2`                         |
| `domain`           | string  | Domínio da certificação                                |
| `question`         | string  | Texto da pergunta em inglês                            |
| `alternatives`     | array   | Lista de 4 alternativas (A–D)                          |
| `correct_answer`   | string  | Letra da alternativa correta (`"A"` – `"D"`)           |
| `explanation_en`   | string  | Explicação original em inglês                          |
| `explanation_ptbr` | string  | Explicação traduzida para português                    |
| `note`             | string  | Campo livre para anotações (vazio por padrão)          |

---

## Arquivo

| Propriedade | Valor               |
|-------------|---------------------|
| Nome        | `NCA-AIIO_QA.json`  |
| Localização | Raiz do projeto     |
| Encoding    | UTF-8               |
| Tamanho     | ~220 KB             |
| Gerado por  | `documentacao/gerar-md.py` + `/tmp/md_to_json.py` |
