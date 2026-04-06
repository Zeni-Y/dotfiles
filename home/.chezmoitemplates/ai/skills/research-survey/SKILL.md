---
name: research-survey
description: "Use this skill when conducting a systematic academic literature survey or registering a single paper into a paper database. Triggers for: (1) Research field queries — user asks to survey a topic, collect papers on X, do a literature review of Y, find papers about Z method — requiring deep multi-source search using paper-search MCP tools; (2) Paper registration — user provides a DOI, title, BibTeX, PDF path, or paper URL for a specific paper and wants it added to the database with a structured explanation document. The skill manages a structured papers/ and surveys/ directory in the working directory, generates Japanese notes.md files per paper using a standard template, assigns method/dataset/evaluation tags using a controlled vocabulary, detects duplicate publications (e.g. Japanese domestic + English extended versions of the same research), clusters papers by research group, and produces survey overview and per-subfield analysis documents with comparison tables. Use whenever the task involves building or extending an academic paper corpus, conducting a literature review, or organizing research papers systematically."
---

# Research Survey Skill

Conduct systematic academic literature surveys and manage a local paper database.

## Directory Structure (in working directory)

```
papers/
  {doi-safe-id}/
    info.json       ← bibliographic data + tags + relationships
    paper.pdf       ← if downloaded
    notes.md        ← structured analysis (Japanese)
surveys/
  {survey-name}/
    config.json     ← survey metadata
    overview.md     ← full-field summary + subfield map
    paper-list.md   ← all-paper comparison table
    subfields/
      {subfield-name}.md
```

**DOI → safe directory ID**: replace `/` with `-` and `.` with `-`
(`10.1234/foo.bar` → `10-1234-foo-bar`)

No DOI fallback: `arxiv-{id}` for arXiv papers, `title-slug-{year}` otherwise
(e.g. `my-paper-title-2024`).

---

## Mode Detection

Read the user's message and decide immediately:

- **Mode 1 (Deep Search)**: User describes a research field or topic with no specific paper → follow Mode 1
- **Mode 2 (Paper Registration)**: User provides a specific paper (DOI / BibTeX / PDF path / URL) → follow Mode 2

If ambiguous, ask: "特定の論文を登録したいですか？それとも分野全体のサーベイを行いますか？"

---

## Mode 1: Deep Search Workflow

### Step 1 — Clarify Survey Scope

Ask the user for:

- **サーベイ名** (directory name, kebab-case, e.g. `dialogue-user-profiling`)
- **リサーチクエスチョン** in one sentence
- **対象年範囲** (default: last 10 years)
- **アンカー論文** — any known key papers or authors
- **言語設定** — survey document language (default: Japanese)

Create `surveys/{survey-name}/config.json`:

```json
{
  "name": "...",
  "description": "...",
  "created": "YYYY-MM-DD",
  "query_field": "...",
  "year_range": "20XX-20XX",
  "anchor_papers": [],
  "searches_performed": []
}
```

### Step 2 — Plan Search Queries

Decompose the field into **5–10 sub-queries** covering:

- Core method / approach
- Application domain variants
- Adjacent techniques
- Historical foundational terms
- Japanese-language equivalents (重要: NLP/HCI 分野では日本語論文も多い)

Show the query plan to the user. Wait for approval before proceeding.
Record approved queries in `config.json` under `searches_performed`.

### Step 3 — Multi-Source Search

For each approved query, search in this order. Stop accumulating when **30+ high-relevance results** are collected.

1. `search_semantic_scholar` — best for citation counts + structured abstracts
2. `search_arxiv` — preprints, essential for NLP/ML/HCI
3. `search_crossref` — broad DOI coverage for published papers
4. `search_google_scholar` — fallback for hard-to-find papers

For specialized fields also try: `search_pubmed` (biomedical), `search_springer`, `search_scopus`.

After all searches: deduplicate by DOI, then by title similarity (>85% match = same paper).
Report the deduplicated list count to the user before proceeding.

### Step 4 — Per-Paper Registration Loop

For each unique paper in the deduplicated list:

1. Compute `doi-safe-id`. Check if `papers/{doi-safe-id}/` already exists.

   - If exists: skip creation; add this survey to its `surveys` list in `info.json` and continue.
   - If not: create directory.

2. Write `info.json` with all available bibliographic fields.
   Leave `tags.method`, `tags.dataset`, `tags.evaluation_metrics` **empty** for now.
   Set `"surveys": ["{survey-name}"]`.

3. Attempt PDF download (try in order, stop at first success):

   - `download_paper` with `platform: "arxiv"` if arXiv ID is known
   - `download_paper` with `platform: "scihub"` using DOI
   - `download_paper` with `platform: "semantic"` if Semantic Scholar paper ID available
     Set `savePath` to the paper directory (`papers/{doi-safe-id}/`).
     On failure: set `pdf_path: null`, record `pdf_url` from search result if available.

4. Generate `notes.md` using the template in `references/templates.md`.
   - Fill all sections from abstract and any full-text content available.
   - For sections requiring full text that is unavailable, write: `PDF未取得のため詳細不明`
   - Write in Japanese unless the survey's `config.json` specifies otherwise.

**⚠️ STOP after all papers are registered. Do NOT assign tags yet — tags are assigned globally in Step 5.**

### Step 5 — Global Tag Assignment

With the full set of papers now visible, do ONE pass across all papers:

1. Read all `info.json` and abstracts / notes in memory.
2. Apply tags from `references/tag-taxonomy.md` to each paper:
   - `tags.method` — primary methods/models used
   - `tags.dataset` — datasets used for training or evaluation
   - `tags.evaluation_metrics` — evaluation metrics reported
   - `tags.has_user_study` — `true` if the paper recruited real users for evaluation
   - `tags.language` — `["ja"]` for Japanese venue, `["en"]` for English, `["ja","en"]` for bilingual
3. Write updated `info.json` for every paper.

Apply tags consistently: if three papers use BERT, all three must use the same tag string `"BERT"`.
If a method isn't in the taxonomy, add it to `references/tag-taxonomy.md` first, then use it.

### Step 6 — Duplicate and Research Group Detection

Scan all papers in this survey:

1. **Same-paper duplicates**: papers with identical DOI, title similarity >90%, or
   same first author + same year + substantially overlapping abstract.
   → Set `duplicate_papers` in each paper's `info.json` pointing to the other DOI(s).
   **Key case**: Japanese domestic workshop paper + extended English journal version by same author.

2. **Research group clustering**: group papers sharing first/last authors or institutional keywords.
   → Set `research_group` (e.g. `"Kyoto-NLP-Lab"`) and `same_research_group` list.

3. **Cross-references**: for each paper, identify other papers in this survey that it would
   likely cite or be cited by. → Set `related_papers`.

Before writing, report detected clusters to the user for confirmation:
"以下の論文が同一研究グループと判定されました: ..."

### Step 7 — Subfield Identification (Bottom-Up)

Do **NOT** pre-define subfields. Instead:

1. Read all notes and tags.
2. Cluster papers by shared method/topic themes emerging from the content.
3. Propose **3–8 subfield names** to the user with paper counts and representative papers.
4. Adjust based on user feedback.
5. Assign each paper to 1–2 subfields. Store assignment in `info.json` under a new `subfields` key.

### Step 8 — Write Survey Documents

**`surveys/{survey-name}/subfields/{subfield-name}.md`** (one per subfield):

```
# {Subfield Name}

## 概要
[What this subfield addresses, 2-3 sentences]

## 歴史的流れ
[Oldest → newest papers; note when key ideas emerged]

## 論文比較表
| 論文 | 年 | 手法 | データセット | 主要結果 | 備考 |
|------|----|----- |------------|---------|------|

## 他サブフィールドとの関係
## 未解決問題・今後の方向性
```

**`surveys/{survey-name}/overview.md`**:

```
# {Survey Name} サーベイ概要

## エグゼクティブサマリー
## サブフィールドマップ
[各サブフィールドと相互関係]
## 全体的なトレンド（時系列）
## 初学者向け推奨読書順序
```

**`surveys/{survey-name}/paper-list.md`**:
Full comparison table sorted by year:

```
| 論文 | 年 | 手法 | データセット | User Study | 評価指標 | サブフィールド |
|------|----|----- |------------|-----------|---------|-------------|
```

---

## Mode 2: Paper Registration Workflow

### Step 1 — Identify the Paper

Extract DOI, title, authors from user input (BibTeX / plain text / PDF path / URL).

If DOI available: call `get_paper_by_doi` to fetch full metadata.
If only title/authors: call `search_semantic_scholar` with title; show top match to user for confirmation.

### Step 2 — Duplicate Check

Compute `doi-safe-id`. Check if `papers/{doi-safe-id}/` exists.

- **Exists**: Report existing entry. Ask: "notes.md を更新しますか？既存のサーベイに追加しますか？"
- **Not exists**: proceed to Step 3.

### Step 3 — Create Paper Entry

1. Create `papers/{doi-safe-id}/`.
2. Write `info.json` from fetched metadata.
3. PDF handling:
   - If user provided a PDF path: record it in `pdf_path` (absolute path).
   - Otherwise attempt `download_paper` (arxiv → scihub → semantic).
4. Generate `notes.md` from abstract and any available full text.
5. Apply tags from `references/tag-taxonomy.md` to `info.json`.

### Step 4 — Survey Linkage

Read all `surveys/*/config.json`. For each survey, check if this paper's tags and topic match the survey's `query_field`. Suggest:

"この論文は以下のサーベイに関連しそうです: [X, Y]. 追加しますか？"

If added: update `info.json` surveys list and append paper row to `paper-list.md`.

---

## File Templates

Full templates are in `references/templates.md`.
Tag vocabulary is in `references/tag-taxonomy.md`.

---

## Error Handling

| Situation                          | Action                                                                                 |
| ---------------------------------- | -------------------------------------------------------------------------------------- |
| DOI not found                      | Use title-slug ID; set `"doi": null` in info.json                                      |
| PDF download fails (all platforms) | Set `"pdf_path": null`; note in notes.md: `PDF未取得のため詳細不明`                    |
| Search returns 0 results           | Reformulate query (broader terms / Japanese alternates); report to user if still empty |
| Conflicting metadata from sources  | Prefer Semantic Scholar > CrossRef > arXiv                                             |
| Rate limit on search platform      | Use `get_platform_status` to check; switch to next platform in the priority order      |

## Constraints

- Never delete existing `papers/` entries. Updates are always additive.
- Do not overwrite `notes.md` unless user explicitly requests re-analysis.
- Tag vocabulary must come from `references/tag-taxonomy.md`; add new terms there before using them.
- Survey documents are written in the language from `config.json` (default: Japanese).
- `overview.md` is always the last document written — it synthesizes all subfield docs.
