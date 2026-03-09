# Project A Agent/Prompt Spec (v1)

This file defines autonomous prompts for the deconstruction workflow.
All agents must return **strict JSON only** and follow shared schema IDs.

## Global rules

- Never copy long original text. Keep summaries abstract and concise.
- Prefer structural fields over literary comments.
- If confidence is low, set `confidence < 0.7` and include `uncertainty_reason`.
- Do not invent characters, rules, or events that are not in the source.
- Every output must include:
  - `metadata.schema_version = "v1"`
  - `metadata.producer = "project-a"`
  - `metadata.created_at`
  - `metadata.updated_at`

---

## Agent A1: Segmenter

### Goal
Split source text into chapter and scene candidate units.

### Input

```json
{
  "book_id": "book_001",
  "raw_text": "<normalized_text>"
}
```

### Output

```json
{
  "book_id": "book_001",
  "chapters": [
    {
      "chapter_no": 1,
      "title": "optional",
      "segments": [
        {
          "segment_id": "seg_001",
          "scene_no": 1,
          "start_offset": 0,
          "end_offset": 2150,
          "scene_cut_confidence": 0.91
        }
      ]
    }
  ]
}
```

---

## Agent A2: ChapterExtractor

### Goal
Build chapter cards from segmented text.

### Input

```json
{
  "book_id": "book_001",
  "chapter_no": 12,
  "chapter_text": "<chapter_text>"
}
```

### Output

```json
{
  "chapter_id": "ch_012",
  "chapter_no": 12,
  "chapter_goal": "string",
  "conflict": "string",
  "turning_point": "string",
  "result": "string",
  "hook": "string",
  "entry_state": {},
  "exit_state": {},
  "confidence": 0.86
}
```

---

## Agent A3: SceneExtractor

### Goal
Build scene cards with objective-obstacle-twist-result fields.

### Input

```json
{
  "book_id": "book_001",
  "chapter_id": "ch_012",
  "scene_text": "<scene_text>"
}
```

### Output

```json
{
  "scene_id": "sc_012_03",
  "scene_goal": "string",
  "obstacles": ["string"],
  "twist": "string",
  "result": "string",
  "emotional_shift": "string",
  "is_foreshadow_setup": false,
  "is_mainline_progress": true,
  "information_delta": {},
  "confidence": 0.88
}
```

---

## Agent A4: CharacterExtractor

### Goal
Extract characters and relation changes.

### Input

```json
{
  "book_id": "book_001",
  "chapter_window": ["ch_010", "ch_011", "ch_012"],
  "text_window": "<window_text>"
}
```

### Output

```json
{
  "characters": [
    {
      "character_id": "char_main",
      "name": "string",
      "role": "string",
      "short_term_goals": ["string"],
      "long_term_goals": ["string"],
      "weakness": "string",
      "arc_summary": "string",
      "confidence": 0.9
    }
  ],
  "relations": [
    {
      "relation_id": "rel_001",
      "source_character_id": "char_main",
      "target_character_id": "char_rival",
      "relation_type": "rivalry",
      "relation_state": "escalating",
      "intensity": 0.74,
      "evidence_chapter_id": "ch_012"
    }
  ]
}
```

---

## Agent A5: WorldRuleExtractor

### Goal
Extract durable world and power rules.

### Input

```json
{
  "book_id": "book_001",
  "chapter_window": ["ch_001", "ch_020"],
  "text_window": "<window_text>"
}
```

### Output

```json
{
  "rules": [
    {
      "rule_id": "rule_001",
      "domain": "power_system",
      "rule_text": "string",
      "resource_binding": "string",
      "cost": "string",
      "violation_penalty": "string",
      "narrative_trigger": "string",
      "confidence": 0.83
    }
  ]
}
```

---

## Agent A6: ForeshadowExtractor

### Goal
Map setup and payoff pairs with lifecycle status.

### Input

```json
{
  "book_id": "book_001",
  "chapter_range": ["ch_001", "ch_120"]
}
```

### Output

```json
{
  "foreshadow_pairs": [
    {
      "foreshadow_id": "fo_021",
      "setup_chapter_id": "ch_012",
      "setup_summary": "string",
      "payoff_chapter_id": "ch_044",
      "payoff_summary": "string",
      "payoff_strength": 0.82,
      "status": "paid"
    }
  ]
}
```

---

## Agent A7: StyleProfiler

### Goal
Produce quantized style metrics for generation constraints.

### Input

```json
{
  "book_id": "book_001",
  "sample_texts": ["<sample_1>", "<sample_2>"]
}
```

### Output

```json
{
  "style_id": "style_001",
  "tone": ["cold", "tense"],
  "dialogue_density": 0.42,
  "avg_sentence_length": 23.1,
  "twist_frequency_per_10k": 4.0,
  "hook_strength": 8.4,
  "info_release_rate": 6.2,
  "action_density": 0.37
}
```

---

## Agent A8: PatternMiner

### Goal
Generalize narrative templates from multiple model packs.

### Input

```json
{
  "book_ids": ["book_001", "book_002", "book_003"],
  "target_genre": ["xianxia", "dungeon"]
}
```

### Output

```json
{
  "patterns": [
    {
      "pattern_id": "pat_101",
      "pattern_type": "opening_hook",
      "genre": ["xianxia"],
      "summary": "string",
      "input_slots": {},
      "expected_output": {},
      "constraints": ["string"],
      "example_refs": ["book_001:ch_001"]
    }
  ]
}
```

---

## Agent A9: QAReviewer

### Goal
Validate extraction outputs before export.

### Input

```json
{
  "book_id": "book_001",
  "target_type": "chapter|scene|character|world_rule|foreshadow|pattern",
  "target_payload": {}
}
```

### Output

```json
{
  "review_id": "qarev_001",
  "target_type": "scene",
  "target_id": "sc_012_03",
  "issue_type": "continuity",
  "severity": "high",
  "issue_detail": "string",
  "fix_suggestion": "string",
  "decision": "open"
}
```

