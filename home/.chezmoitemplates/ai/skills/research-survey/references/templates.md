# File Templates

## notes.md Template

Use this structure when generating paper notes. Write in flowing Japanese prose — avoid bare bullet points.
When information is unavailable (PDF not obtained), write `PDF未取得のため詳細不明`.
Write in Japanese unless the survey config specifies otherwise.

The opening paragraph (before any heading) should be a 2–4 sentence hook that explains
**what the paper is really doing and why it matters**, written as if explaining to a colleague.

---

```markdown
# {title}

{冒頭段落: この論文が何を検証/提案しているかを 2〜4 文で平易に説明する。研究の核心的な問いと、なぜそれが重要かを伝える。箇条書き不可。}

## 論文の基本情報

タイトルは **"{title}"** で、{venue} {year}年 採択論文です。著者は {authors} です。DOI: {doi} / PDF: {pdf_path or pdf_url}

## この論文の問題意識

{先行研究や実世界での課題を説明する。著者がどんな不満・問題意識から出発したかを丁寧に記述する。キーとなる概念があれば **太字** で定義する。}

## 研究目的と問い

{この研究が答えようとしている問いを明示する。複数の問いがある場合は番号付きリストで整理する。}

## 実験デザイン

{実験・研究の設計を説明する。被験者数・条件・使用ツール・質問票など具体的な数値を含める。サブセクションを使って整理しても良い。}

## 何を評価したか

{指標・評価方法・測定内容を説明する。各指標の意味と解釈方法も記述する。}

## 主な結果

{結果を番号付きで記述する。各結果について、数値と著者の解釈を合わせて記述する。「〜だった」で終わるのではなく、「著者は〜と解釈している」まで書く。}

## この論文の貢献

{先行研究との差分・新規性を説明する。この論文が初めて示したこと、方法論上の工夫などを記述する。サーベイの研究関心と絡めて、どう位置づけられるかも書く。}

## 限界

{著者が認めている限界、または読んで気づく限界を記述する。一般化可能性・手法の制約・未解決問題など。}

## まとめ

{この論文の結論を 2〜3 文で簡潔にまとめる。}

### 引用での言及例

{学術論文の「関連研究」節に書くような 3 文構成の日本語文を書く。
1 文目: 著者らの目的・対象。
2 文目: 手法・アプローチの説明。
3 文目: 主な結果と含意。
文末は「〜した．」形式の書き言葉で統一。}
```

---

## info.json Schema

```json
{
  "doi": "10.xxxx/xxxxx",
  "title": "Full paper title",
  "authors": ["Lastname, Firstname", "Lastname, Firstname"],
  "year": 2024,
  "venue": "ACL / EMNLP / IJCAI / 言語処理学会 / etc.",
  "abstract": "Full abstract text",
  "pdf_path": "paper.pdf",
  "pdf_url": "https://...",
  "tags": {
    "method": [],
    "dataset": [],
    "has_user_study": false,
    "evaluation_metrics": [],
    "language": ["en"]
  },
  "related_papers": [],
  "same_research_group": [],
  "duplicate_papers": [],
  "research_group": "",
  "surveys": [],
  "subfields": []
}
```

### Field Notes

**`pdf_path`**:

- `"paper.pdf"` — file downloaded into the paper's own directory
- `"/absolute/path/to/file.pdf"` — user-provided PDF stored elsewhere
- `null` — no PDF available

**`language`** (ISO 639-1):

- `["ja"]` — Japanese venue / Japanese full text
- `["en"]` — English venue / English full text
- `["ja", "en"]` — Japanese conference paper with English abstract, or dual-published

**`duplicate_papers`**: list DOIs of papers that are essentially the same research
(e.g. domestic workshop paper + extended English journal version).

**`same_research_group`**: list DOIs of other papers by the same lab/research group
(even if content is different).

**`subfields`**: list of subfield names (from the survey's subfield classification)
that this paper belongs to. Max 2 entries.
