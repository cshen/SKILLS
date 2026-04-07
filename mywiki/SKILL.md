---
name: personal-wiki
description: Build and maintain a personal knowledge wiki. Use when users need to collect and organize knowledge, manage research notes, build a persistent knowledge system, or document problem-solving experiences.
version: 1.1.0
tags:
  - knowledge-base
  - wiki
  - research
  - note-taking
---


# Personal Wiki

Turn your LLM into a Wiki maintainer. The LLM incrementally builds and maintains a persistent, interconnected Markdown knowledge base. Knowledge is **compiled once and continuously updated**, rather than re-derived each time.

This is the key difference from RAG: **the wiki is a persistent, compounding artifact.** Cross-references are already there. Contradictions have already been flagged. The synthesis already reflects everything you've read. The wiki gets richer with every source added and every question asked.

**Division of labor:**
- **You**: curate sources, direct analysis, ask good questions
- **LLM**: all the bookkeeping — summarizing, cross-referencing, filing, maintaining consistency across pages

Inspired by:
- [Karpathy - LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — Incremental knowledge base architecture
- [Compound Engineering Plugin](https://github.com/EveryInc/compound-engineering-plugin) — Knowledge compounding: every problem-solving experience should make the next one easier

## When to Use

**The AI should proactively identify and use this skill when:**

1. **User wants to build a knowledge base** — "Help me organize these materials", "I want to create a wiki" / "帮我整理这些材料", "我想建一个知识库"
2. **User provides new learning materials** — Shares an article, paper, or book chapter that needs organizing / 分享了文章、论文、书籍章节
3. **User wants to query existing knowledge** — "What did I previously read about this concept?" / "我之前读过关于这个概念的什么内容？"
4. **User wants to maintain wiki health** — "Check the wiki for contradictions" / "检查一下知识库", "清理一下知识库"
5. **User solved a problem** — "Done", "Fixed it", "That worked" / "搞定了", "修好了", "解决了"
6. **User is doing long-term research** — A weeks- or months-long research topic requiring gradual knowledge accumulation

**When NOT to use:**
- One-off Q&A that doesn't need persistent knowledge

## Entry Point

> **Language policy:** The user may communicate in English or Chinese. Always respond in the same language the user used. Wiki page **filenames and frontmatter fields** always remain in English. **Wiki page body content** follows the language of the primary source document: if the source is predominantly Chinese, write the page body in Chinese; if predominantly English, write in English. Mixed-source pages default to English.

### Step 1: Determine User Intent

Based on what the user says, determine which operation to execute:

| User Intent | Operation |
|-------------|-----------|
| "Create a knowledge base", "Initialize wiki" / "创建知识库", "初始化 Wiki" | init |
| "Help me process this article", "I have new materials", "Check out this link" / "帮我处理这篇文章", "我有新材料", "看看这个链接" | ingest |
| "Done", "Fixed it", "Problem solved" / "搞定了", "修好了", "解决了", "我发现了一个规律" | compound |
| "What is X?", "Summarize Y for me" / "X 是什么？", "帮我总结一下 Y" | query |
| "Check the wiki", "Clean up the knowledge base" / "检查一下知识库", "清理知识库" | lint |
| Intent unclear | Ask user to choose |

**When intent is unclear, ask (in the user's language):**

```
# English
Which operation would you like to run?
  1. init     - Initialize knowledge base
  2. ingest   - Ingest new materials
  3. compound - Document problem-solving experience
  4. query    - Query existing knowledge
  5. lint     - Health check

# 中文
你想执行哪个操作？
  1. init     - 初始化知识库
  2. ingest   - 录入新材料
  3. compound - 记录解题经验
  4. query    - 查询已有知识
  5. lint     - 健康检查
```

### Step 2: Check if Initialized

Before any operation (except init itself), check if the wiki exists:

- **Exists** → Proceed with the target operation
- **Does not exist** → Auto-execute init first without asking, then proceed with the target operation

```bash
ls ~/Personal_wiki/wiki/index.md 2>/dev/null
```

---

## Operation: init

### When to Execute

- User explicitly requests initialization
- Auto-executed when `~/Personal_wiki/wiki/` doesn't exist before other operations

### Workflow

#### 1. Create Directory Structure

```bash
mkdir -p ~/Personal_wiki/raw/{articles,papers,books,notes,assets,misc}
mkdir -p ~/Personal_wiki/wiki/{entities,concepts,topics,sources,solutions}
```

Adjust `raw/` subdirectories based on knowledge base topics mentioned in prior conversation. `misc/` is always created as a catch-all for uncategorized materials.

#### 2. Create index.md

`index.md` is **content-oriented**: a catalog of every page with a one-line summary, organized by category. The LLM reads this first on every query to locate relevant pages without scanning all files.

```markdown
# Wiki Index

## Overview
- [[overview]] - Overall summary and key findings

## Sources
<!-- Ingested raw material summaries — format: - [[YYYY-MM-DD-name]] - one-line description, sorted by date descending -->

## Entities
<!-- People, organizations, products — format: - [[name]] - one-line description, sorted by name -->

## Concepts
<!-- Theories, methods, terminology — format: - [[concept-name]] - one-line description, sorted by name -->

## Topics
<!-- Synthesized analyses, comparisons, explorations — format: - [[topic-name]] - one-line description, sorted by name -->

## Solutions
<!-- Problem-solving experiences (compound) — format: - [[YYYY-MM-DD-name]] - one-line description, sorted by date descending -->
```

#### 3. Create log.md

`log.md` is **chronological**: an append-only record of all operations. Each entry uses a consistent prefix so it's grep-parseable.

```markdown
# Wiki Log

<!-- Append entries chronologically. Format: ## [YYYY-MM-DD] operation 
- description 1 
- description 2 
.. -->
<!-- grep "^## \[" log.md | tail -5   →  last 5 operations -->
```

#### 4. Create overview.md

```markdown
---
type: overview
created: YYYY-MM-DD
---

# Knowledge Base Overview

> This Wiki is automatically maintained by LLM. You handle topic selection and questions; the LLM handles summarization, cross-referencing, archiving, and maintenance.

## Current Status
- Source count: 0
- Total pages: 0 (including index, log, overview)
- Last updated: -

## Evolving Thesis
<!-- The most important synthesis and emerging conclusions across all sources -->

## Key Findings
<!-- Specific high-value facts, patterns, or insights discovered so far -->

## Open Questions
<!-- Gaps identified — topics to explore, sources to find, contradictions to resolve -->
```

#### 5. Output Confirmation

```
Wiki knowledge base initialized! ~/Personal_wiki/

Next steps:
  - Put materials in raw/, I'll organize them (ingest)
  - Give me a link or text, I'll save and process it (ingest)
  - Tell me when you've solved a problem, I'll document it (compound)
  - Ask me about existing knowledge in the Wiki anytime (query)
  - Let me check the Wiki's health (lint)
```

If auto-initialized (not user-initiated), simplify output to one line: `Auto-initialized knowledge base ~/Personal_wiki/`, then proceed with the target operation.

---

## Operation: ingest

Process new raw materials and integrate knowledge into the Wiki. A single new material may affect 10–15 Wiki pages.

### Workflow

#### 1. Determine Materials to Process

By priority:
1. **User specified specific material** (link, text, file path) → Process only that material
2. **User says "process new materials"** → Scan `raw/` for unprocessed files
3. **User says "process all new materials"** → Batch process

**Determining processed/unprocessed:** Compare `raw/` files against the `source` frontmatter field in `wiki/sources/`. A corresponding summary page = processed.

```
Found 3 unprocessed materials:
  1. raw/articles/attention-paper.pdf
  2. raw/notes/meeting-2026-04-05.md
  3. raw/papers/bert-paper.pdf

Process all, or select specific ones? (Default: all)
```

#### 2. Save Raw Materials (URL/text only)

- **URL** → Fetch and save to `raw/articles/`
- **Text** → Save to `raw/notes/`
- **Existing file** → Read directly

#### 3. Read and Extract

Read the raw material, identifying: core arguments, key entities, important concepts, data/facts, and relationships to existing wiki content.

> **PDF Rule**: Always use the PDF skill (`~/.agents/skills/pdf` which is available at https://github.com/anthropics/skills/tree/main/skills/pdf) to process PDF files. For scanned/image-based PDFs that return little or no text from `pdftotext`, use OCR via `pytesseract` + `pdf2image` (as provided by the skill). Never skip a PDF because it appears empty — always attempt OCR first.
>
> ```python
> import pytesseract
> from pdf2image import convert_from_path
> images = convert_from_path('scanned.pdf', dpi=200)
> text = "\n".join(pytesseract.image_to_string(img) for img in images)
> ```

> **Image Rule**: LLMs can't read markdown with inline images in one pass. When processing a source with images, first extract all text using the `~/.agents/skills/image-ocr` skill, and metadata, then view the referenced images separately to extract information. Don't let the presence of images prevent you from processing the text content.

#### 4. Discuss with User (Recommended; skip for batch processing)

```
Core points of this material:
1. ...
2. ...

Key entities/concepts involved: A, B, C
Which aspects would you like to focus on?
```

#### 5. Create Source Summary Page

Create in `wiki/sources/`, filename: `YYYY-MM-DD-short-name.md`

```markdown
---
type: source
date: YYYY-MM-DD
source: raw/path/to/file
tags: [tag1, tag2]
---

# Source: Title

## Key Points
- Point 1

## Key Quotes
> Original quote

## Relationships to Other Sources
- Corroborates [[other-source]] on X
- Contradicts [[contradicting-source]] on Y

## Derived Concepts
- [[concept-a]]
```

#### 6. Update Entity and Concept Pages

For each entity and concept mentioned in the material:
- **Existing page** → Append new information, cite source
- **New page** → Create using template

Entity/concept page template:

```markdown
---
type: entity  # or concept
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [source-a, source-b]
---

# Name

## Definition
Brief description.

## Key Information
- Info point 1 (Source: [[source-a]])

## Relations
- Related concepts: [[concept-x]]

## Open Questions
- Unanswered questions
```

Note:
- When new information contradicts existing content, keep both versions with clear annotations
- Every factual claim must cite its source

#### 7. Update Topic Pages (if needed)

#### 8. Update index.md, overview.md

Update `index.md` with new/changed pages (one-line summaries). Update `overview.md`'s evolving thesis and key findings if anything significant changed.

#### 9. Append to log.md

```markdown
## [YYYY-MM-DD] ingest | Material Title

- **Source**: raw/path/to/file
- **New pages**: page-a, page-b
- **Updated pages**: page-c, page-d
- **Impact scope**: N pages
```

#### 10. Output Summary

```
Processing complete.

New:
  - Source summary: [[source-name]]
  - Entities: [[entity-a]], [[entity-b]]
  - Concepts: [[concept-c]]

Updated:
  - [[concept-d]] - Added details about X

Warning - Contradictions found:
  - Description of Y in [[concept-d]] is inconsistent with [[source-old]]
```

---

## Operation: compound

Document problem-solving experiences into `wiki/solutions/`. Knowledge compounding: invest time researching once, document it, solve it in minutes next time.

### When to Execute

- User says "Done", "Fixed it", "Problem solved" / "搞定了", "修好了", "解决了"
- User just finished a debugging session, investigation, or analysis and the outcome is worth preserving
- User discovered a pattern, trick, or best practice worth recording / "我发现了一个规律", "有个经验想记录一下"

**Not worth recording:** Typos, obvious minor fixes, one-off non-reproducible issues. Just tell the user why.

### Dual Tracks

**Bug Track** (Problem Resolution): For fixing bugs, resolving errors.

```markdown
---
type: solution
track: bug
date: YYYY-MM-DD
tags: [tag1, tag2]
---

# Problem Title

## Problem
1-2 sentence description.

## Symptoms
- Observable abnormal behavior

## Investigation
1. ❌ Attempt A → Reason for failure
2. ✅ Final solution

## Root Cause
Explanation of the cause.

## Solution
\`\`\`
// Before
...
// After
...
\`\`\`

## Prevention
How to avoid recurrence.

## Relations
- [[concept-a]]
```

**Knowledge Track** (Insights): For summarizing patterns, best practices, workflow tips.

```markdown
---
type: solution
track: knowledge
date: YYYY-MM-DD
tags: [tag1, tag2]
---

# Insight Title

## Background
Context in which this experience was gained.

## Guidance
Specific practices, patterns, or recommendations.

## Why It Matters
Impact of following or not following this practice.

## When to Apply
Conditions under which this experience applies.

## Relations
- [[concept-a]]
```

### Workflow

1. **Extract information from context** — Problem description, investigation process, root cause, solution, key code
2. **Choose track** — Solved a specific problem → Bug Track; Summarized experience/pattern → Knowledge Track
3. **Check for overlap** — Search `wiki/solutions/` for similar documents. High overlap → Update existing; Low or none → Create new
4. **Write document** — `wiki/solutions/YYYY-MM-DD-short-name.md`
5. **Update** index.md, overview.md, log.md
6. **Output summary**

---

## Operation: query

Answer questions based on Wiki content. Good answers are **filed back into the wiki** — explorations compound just like ingested sources.

### Core Principle

Never re-derive from the wiki what can simply be read from it. And never let a valuable synthesis vanish into chat history — if the answer required multi-source reasoning, a comparison, or a new discovery, save it.

### Workflow

1. **Read index.md first** — get the full map of what exists; identify the 2–5 most relevant pages
2. **Read relevant pages** — drill into sources, concepts, topics, and solutions pages
3. **Synthesize answer** — cite with `[[wikilink]]`, annotate sources
4. **Archive valuable answers** — if the answer involved multi-source synthesis, a comparison table, or a new connection, save to `wiki/topics/` as a new page and add to index.md
5. **Suggest further exploration** — flag information gaps, contradictions noticed, or sources worth finding

### Output Formats

Answers can take different forms depending on the question:
- Standard markdown response with `[[wikilink]]` citations
- Comparison table
- Slide deck (Marp format, if requested)
- Chart (matplotlib script, if requested)

---

## Operation: lint

Detect contradictions, orphan pages, stale claims, and other issues to maintain long-term Wiki health.

### When to Execute

- User says "check the wiki", "clean up the knowledge base" / "检查一下知识库", "清理知识库"
- Periodically when the wiki accumulates 20+ pages
- After ingesting a batch of important materials

### 6 Checks

| Check | Method |
|-------|--------|
| Contradiction detection | Compare descriptions of the same topic across different pages; flag conflicting claims |
| Stale content | Pages whose `updated` date predates a newer source on the same topic — claims may have been superseded |
| Orphan pages | Pages with 0 inbound `[[wikilink]]` references |
| Missing pages | Linked via `[[wikilink]]` but the target file does not yet exist |
| Missing cross-references | Pages sharing 2+ sources but not linked to each other |
| Data gaps | "Open questions" on concept pages; unexplored directions noted in overview |

### Workflow

1. Read full picture: `ls -R wiki/` + read `wiki/index.md`
2. Run each check
3. Generate report: statistics + issues listed by priority (High / Medium / Low)
4. Ask user whether to auto-fix (create missing pages, add cross-references, etc.)
5. Execute fixes, append to log.md

Note: Process each file in raw/ **only once** and remember that. 

---

## Three-Layer Architecture

```
~/Personal_wiki/
│
├── README.md               ← Schema (this file): conventions, workflows, page formats
│                             The LLM reads this to behave as a disciplined wiki maintainer.
│                             Co-evolve with the LLM as your domain develops.
│
├── raw/                    ← Raw sources (immutable — LLM reads, never modifies)
│   ├── articles/
│   ├── papers/
│   ├── books/
│   ├── notes/
│   ├── assets/
│   └── misc/               # Uncategorized materials — drop anything here without sorting
│
└── wiki/                   ← LLM-maintained Wiki (LLM writes everything here)
    ├── index.md            # Content catalog — read first on every query
    ├── log.md              # Append-only operation log — grep-parseable
    ├── overview.md         # Evolving synthesis and key findings
    ├── entities/           # Organisations, products, places
    ├── persons/            # Individual people (auto-created when mentioned >10 times)
    ├── concepts/           # Theories, methods, terminology
    ├── topics/             # Synthesized analyses, comparisons
    ├── sources/            # Source summary pages
    └── solutions/          # Compound: bug fixes and insights
```

The wiki is a plain git repo of markdown files — you get version history, branching, and diffs for free.

## File Naming Convention

| Type | Path Format |
|------|-------------|
| Source summary | `wiki/sources/YYYY-MM-DD-short-name.md` |
| Entity page | `wiki/entities/name.md` |
| Person page | `wiki/persons/firstname-lastname.md` |
| Concept page | `wiki/concepts/concept-name.md` |
| Topic page | `wiki/topics/topic-name.md` |
| Solution document | `wiki/solutions/YYYY-MM-DD-short-name.md` |

All filenames use lowercase English with hyphens.

## Writing Standards

- Start each page with YAML frontmatter (`type`, `date`, `tags`, `sources`)
- Use `[[wikilink]]` for all inter-page references
- Cite sources for every factual claim
- When new and old information contradict, keep both versions annotated — never silently overwrite
- Keep pages concise and focused on one topic

### Person Pages (`wiki/persons/`)

- **Trigger**: automatically create `wiki/persons/firstname-lastname.md` when a person is mentioned more than 10 times across all wiki content (sources, entities, topics, concepts)
- **Content**: biography summary, known roles, relationships, key facts, open questions — all sourced from ingested material
- **Language**: follows the dominant language of sources mentioning this person
- **Filename**: lowercase English with hyphens, e.g. `jacky-chen.md`, `michael-jordan.md`
- **During ingest/compound**: count mentions mentally; if a person crosses the threshold, create the page immediately

## Obsidian Integration

Open `~/Personal_wiki/` directly as an Obsidian vault.

**Useful setup:**
- **Graph View** — see the shape of your wiki; identify hubs and orphans visually
- **Obsidian Web Clipper** (browser extension) — converts web articles to markdown; fastest way to get sources into `raw/`
- **Download attachments** — In Settings → Files and links, set attachment folder to `raw/assets/`. Bind "Download attachments for current file" to a hotkey (e.g. Ctrl+Shift+D) so clipped images are saved locally
- **Dataview plugin** — queries over YAML frontmatter; generates dynamic tables from `type`, `date`, `tags`, `sources` fields
- **Marp plugin** — render `wiki/topics/` pages as slide decks directly from markdown

**Note on images:** LLMs can't read markdown with inline images in one pass. Workaround: have the LLM read the text first, then view referenced images separately.

## Tips & Tricks

- **Ingest one source at a time** when quality matters — stay involved, read summaries, guide emphasis. Batch ingest when volume matters more.
- **File good query answers back** — a comparison you asked for, an analysis, a connection you spotted. Don't let them disappear into chat history.
- **Log is grep-parseable** — `grep "^## \[" wiki/log.md | tail -10` gives the last 10 operations at a glance.
- **Search at scale** — the index file works well up to ~100 sources / hundreds of pages. Beyond that, consider [qmd](https://github.com/tobi/qmd): local hybrid BM25/vector search for markdown with both a CLI and MCP server.
- **overview.md is the thesis** — treat "Evolving Thesis" as a living synthesis that sharpens as sources accumulate, not just a status field.
- **Schema is co-evolved** — update this README as you develop conventions for your domain. Future sessions inherit your accumulated workflow knowledge.

## Examples

### ingest (English)

```
User: I put the Attention Is All You Need paper in raw/papers/

Agent: I'll process this paper.

[Reads raw/papers/attention-is-all-you-need.pdf]
[Extracts key information]

Core points of this paper:
1. Proposed the Transformer architecture, entirely based on attention mechanisms, abandoning RNN/CNN
2. Introduced Multi-Head Self-Attention and Positional Encoding
3. Achieved SOTA on machine translation tasks

Entities involved: Google Brain, Ashish Vaswani and 7 other authors
Concepts involved: Self-Attention, Multi-Head Attention, Positional Encoding, Layer Normalization

Which aspects would you like to focus on?

User: Focus on the design rationale behind Self-Attention

Agent: [Creates wiki/sources/2026-04-06-attention-paper.md]
[Creates wiki/concepts/self-attention.md - Focuses on design rationale]
[Creates wiki/entities/transformer.md]
[Creates wiki/entities/google-brain.md]
[Creates wiki/concepts/multi-head-attention.md]
[Creates wiki/concepts/positional-encoding.md]
[Updates wiki/overview.md]
[Updates wiki/index.md]
[Appends to wiki/log.md]

Processing complete. 6 new pages created. The Self-Attention concept page focuses on the design motivation behind Scaled Dot-Product.
```

### ingest (中文)

```
用户：我把《注意力机制》的论文放到 raw/papers/ 了

Agent：好的，我来处理这篇论文。

[读取 raw/papers/attention-is-all-you-need.pdf]
[提取关键信息]

这篇论文的核心要点：
1. 提出了完全基于注意力机制的 Transformer 架构，放弃了 RNN/CNN
2. 引入了多头自注意力（Multi-Head Self-Attention）和位置编码（Positional Encoding）
3. 在机器翻译任务上达到了 SOTA 效果

涉及的实体：Google Brain、Ashish Vaswani 等 8 位作者
涉及的概念：Self-Attention、Multi-Head Attention、Positional Encoding、Layer Normalization

你希望重点关注哪些方面？

用户：重点关注 Self-Attention 的设计思路

Agent：[创建 wiki/sources/2026-04-06-attention-paper.md]
[创建 wiki/concepts/self-attention.md — 聚焦设计思路]
[创建 wiki/entities/transformer.md]
[创建 wiki/entities/google-brain.md]
[创建 wiki/concepts/multi-head-attention.md]
[创建 wiki/concepts/positional-encoding.md]
[更新 wiki/overview.md]
[更新 wiki/index.md]
[追加到 wiki/log.md]

处理完成，新建 6 个页面。Self-Attention 概念页聚焦于 Scaled Dot-Product 背后的设计动机。
```

### compound (English — Bug Track)

```
User: Fixed it, it was a database connection pool configuration issue

Agent: This is worth documenting. Let me organize it.

[Reviews conversation context]
[Checks wiki/solutions/ for overlap]
[Creates wiki/solutions/2026-04-06-db-connection-pool-exhausted.md]

Experience documented. Bug Track.

Summary:
  Problem: Database connection pool exhaustion under high concurrency, causing request timeouts
  Root cause: Default pool size of 5 was too small; no idle timeout recycling was configured
  Solution: Increased pool size to 20, added idle timeout configuration

Linked to existing [[database-connections]] concept page in the Wiki.
```

### compound (中文 — Knowledge Track)

```
用户：我发现处理搜索输入时，用 debounce 比 throttle 效果更好

Agent：好的，这个经验值得记录下来。

[创建 wiki/solutions/2026-04-06-debounce-vs-throttle-search.md]
[检查是否有相关概念页]

经验已记录。Knowledge Track。

核心建议：搜索输入场景应使用 debounce（等待用户停止输入后触发），
而非 throttle（按固定间隔触发），因为搜索需要完整的关键词。

Wiki 中暂无 debounce 和 throttle 的概念页，要顺手创建吗？
```

### query (English)

```
User: What's the difference between Self-Attention and regular Attention?

Agent: [Reads wiki/index.md]
[Locates wiki/concepts/self-attention.md, wiki/concepts/attention.md]
[Synthesizes answer]

## Self-Attention vs Regular Attention

**Regular Attention** (Source: [[source-a]]):
- Query and Key/Value come from different sequences
- Typical scenario: target language attending to source language in translation

**Self-Attention** (Source: [[2026-04-06-attention-paper]]):
- Query, Key, and Value all come from the same sequence
- Each position can attend to all other positions in the sequence

| Dimension | Regular Attention | Self-Attention |
|-----------|-------------------|----------------|
| Q/K/V Source | Q ≠ KV | Q = K = V |
| Captures | Cross-sequence | Within-sequence |
| Complexity | O(n×m) | O(n²) |

This comparison has been saved as [[self-attention-vs-attention]].
```

### query (中文)

```
用户：Self-Attention 和普通 Attention 有什么区别？

Agent：[读取 wiki/index.md]
[定位 wiki/concepts/self-attention.md、wiki/concepts/attention.md]
[综合整理答案]

## Self-Attention vs 普通 Attention

**普通 Attention**（来源：[[source-a]]）：
- Query 和 Key/Value 来自不同的序列
- 典型场景：翻译任务中目标语言关注源语言

**Self-Attention**（来源：[[2026-04-06-attention-paper]]）：
- Query、Key、Value 均来自同一序列
- 每个位置都可以关注序列中的所有其他位置

| 维度 | 普通 Attention | Self-Attention |
|------|----------------|----------------|
| Q/K/V 来源 | Q ≠ KV | Q = K = V |
| 捕捉关系 | 跨序列 | 序列内部 |
| 复杂度 | O(n×m) | O(n²) |

该对比已保存为 [[self-attention-vs-attention]]。
```

### lint (中文)

```
用户：帮我检查一下知识库

Agent：[读取 wiki/index.md]
[扫描所有 wiki/ 页面]

Wiki 健康报告 — 2026-04-06
页面总数：12 | 来源：3 | 概念：6 | 实体：2 | 主题：1

#### 陈旧内容（1 处）
1. [[positional-encoding]] 上次更新早于 [[2026-04-06-rope-paper]] 的录入时间，内容可能已过时

#### 孤立页面（1 处）
1. [[layer-normalization]] — 无任何页面引用

#### 缺失页面（2 处）
1. [[residual-connection]] — 被引用 4 次
2. [[softmax]] — 被引用 2 次

### 建议操作
1. [高优] 创建 [[residual-connection]]（被引用 4 次）
2. [高优] 创建 [[softmax]]（被引用 2 次）
3. [中优] 对照 [[2026-04-06-rope-paper]] 审查 [[positional-encoding]]
4. [低优] 为 [[layer-normalization]] 添加入站引用

要自动修复吗？

用户：先处理 1 和 2

Agent：[创建 wiki/concepts/residual-connection.md]
[创建 wiki/concepts/softmax.md]
[更新 wiki/index.md]
[追加到 wiki/log.md]

已创建：
- [[residual-connection]] — 基于 [[attention-paper]] 中的描述
- [[softmax]] — 作为 Self-Attention 中的关键计算步骤

3 和 4 留待你准备好后再处理。
```

## Use Cases

**Active Learning (ingest):**
- Academic research, reading notes, competitive analysis, course notes, book reading (build a companion wiki chapter by chapter)

**Experience Accumulation (compound):**
- Engineering practices (bug fixes, best practices), team knowledge base, workflow optimization, personal growth

**Personal / Long-term:**
- Health and self-improvement journals, goal tracking, psychology notes — build a structured picture of yourself over time
