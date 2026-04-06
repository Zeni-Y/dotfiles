# Tag Taxonomy

Controlled vocabulary for `info.json` tags. Always prefer an existing term.
When a paper uses a method/dataset/metric not listed, add it here first, then apply it.

---

## method tags

### Large Language Models

- GPT-2, GPT-3, GPT-3.5, GPT-4, ChatGPT, GPT-4o
- LLaMA, LLaMA-2, Mistral, Gemma
- Claude, PaLM, Gemini
- T5, FLAN-T5, BART
- prompt-engineering, in-context-learning, chain-of-thought
- fine-tuning, instruction-tuning, RLHF, DPO
- few-shot, zero-shot, RAG

### BERT-family

- BERT, RoBERTa, ALBERT, DeBERTa
- XLNet, ELECTRA
- Japanese-BERT, cl-tohoku-bert

### Sequence Models (pre-Transformer)

- BiLSTM, LSTM, GRU
- CNN-text
- seq2seq, attention-mechanism
- word2vec, GloVe, fastText

### Dialogue Systems

- task-oriented-dialogue, open-domain-dialogue
- slot-filling, intent-detection
- dialogue-state-tracking, response-generation
- persona-based, knowledge-grounded
- mixed-initiative, dialogue-management
- rule-based-dialogue, frame-based

### Information Extraction / NLP

- named-entity-recognition, NER
- relation-extraction
- coreference-resolution
- event-extraction
- dependency-parsing, constituency-parsing
- sentiment-analysis, opinion-mining

### User Modeling / Profiling

- user-attribute-extraction
- preference-extraction
- interest-modeling
- knowledge-tracing
- user-simulator

### Recommendation / Personalization

- collaborative-filtering
- content-based-filtering
- knowledge-graph
- graph-neural-network, GCN, GAT
- reinforcement-learning, bandit, DQN

### Crowdsourcing / Annotation

- crowdsourcing, MTurk
- active-learning
- human-in-the-loop
- annotation-agreement, inter-annotator-agreement

### Other Methods

- rule-based, pattern-matching, regex
- CRF, conditional-random-field
- SVM, random-forest, logistic-regression
- data-augmentation
- knowledge-distillation, contrastive-learning
- multimodal

---

## dataset tags

### Dialogue / Conversational

- MultiWOZ (specify version: MultiWOZ-2.0, MultiWOZ-2.1, ...)
- DailyDialog
- PersonaChat
- Wizard-of-Wikipedia
- DSTC (specify: DSTC2, DSTC3, DSTC8, ...)
- SGD (Schema-Guided Dialogue)
- JDDC (Japanese dialogue)
- ReDial (recommendation dialogue)

### Social Media / Web

- Twitter, X
- Reddit
- Amazon-reviews
- Wikipedia
- CommonCrawl

### Question Answering

- SQuAD, SQuAD2.0
- TriviaQA, Natural Questions
- HotpotQA
- JAQKET (Japanese QA)

### User Study / Lab-Collected

- crowdsourced (collected via MTurk or similar)
- expert-annotated
- lab-study (participants recruited in laboratory setting)
- Wizard-of-Oz (human plays system role)

### Survey / Questionnaire

- self-report-questionnaire
- Likert-scale-survey

### Other

- synthetic (machine-generated)
- proprietary (not publicly available — note this)

---

## evaluation_metrics tags

### Classification / Extraction

- accuracy, F1, precision, recall
- exact-match
- BLEU, ROUGE, METEOR, BERTScore
- perplexity

### Ranking / Retrieval

- MRR (Mean Reciprocal Rank)
- NDCG
- MAP
- hit-rate, recall@K

### Dialogue-specific

- task-completion-rate
- turn-count, dialogue-length
- success-rate
- slot-error-rate

### User-Centric

- human-evaluation (overall quality rated by annotators)
- user-study-score (scores from recruited participants)
- naturalness, fluency, coherence (specific human eval dimensions)
- satisfaction, engagement
- SUS (System Usability Scale)

### Other

- RMSE, MAE (regression tasks)
- AUC-ROC
- inter-annotator-agreement, kappa

---

## Notes

- `has_user_study: true` = paper recruited real users (crowdworkers or lab participants)
  for evaluation, not just automatic metrics.
- A paper may have multiple values per tag field.
- When a paper proposes a new dataset, add its name to the dataset section above.
- Keep tag strings lowercase-with-hyphens for consistency.
