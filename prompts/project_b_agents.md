# Project B Agent/Prompt Spec (v1)

This file defines autonomous prompts for planning -> writing -> review -> memory writeback.
All outputs must be strict JSON and conform to shared schema v1.

## Global rules

- Use only structured assets as inputs (StoryBible, OutlinePack, MemorySnapshot, StyleProfile refs).
- Do not generate content outside the current scene boundary.
- Facts added in draft must be extractable and writable into memory.
- Critical review issues block memory writeback.
- Every output includes metadata:
  - `schema_version = "v1"`
  - `producer = "project-b"`
  - `created_at`
  - `updated_at`

---

## Agent B1: TopicGenerator

### Goal
Generate constrained topic ideas from pattern packs.

### Input

```json
{
  "project_id": "proj_001",
  "genre": ["修仙", "副本"],
  "target_platform": "男频",
  "audience": ["升级流", "智斗向"],
  "constraints": {
    "forbidden_elements": ["纯恋爱"],
    "must_have": ["高压规则", "信息差"]
  },
  "pattern_pack_refs": ["gpp_xianxia_001"],
  "top_k": 10
}
```

### Output

```json
{
  "items": [
    {
      "idea_id": "idea_001",
      "project_id": "proj_001",
      "logline": "string",
      "genre": ["string"],
      "selling_points": ["string"],
      "risk_flags": ["string"],
      "score_estimate": {
        "hook": 8.7,
        "serial_potential": 8.1,
        "differentiation": 7.9
      }
    }
  ],
  "total": 10
}
```

---

## Agent B2: TopicEvaluator

### Goal
Rank and score topic ideas for serial sustainability and hook strength.

### Output extension
- Add rank and rejection reasons for low-ranked ideas.

---

## Agent B3: StoryBibleBuilder

### Goal
Generate the project constitution from selected idea + patterns.

### Output
- `StoryBible` object with hard constraints and ending direction.

Hard checks:
- Rules cannot contradict themselves.
- Protagonist growth path must include cost.

---

## Agent B4: MasterOutliner

### Goal
Generate full-book master outline.

### Output requirements
- explicit mainline question
- act structure
- volume themes
- ending route

---

## Agent B5: VolumeOutliner

### Goal
Expand master outline into volume arcs.

### Output requirements
- one `arc_id` per volume
- opening state / goal / core enemy / climax / ending hook

---

## Agent B6: ChapterOutliner

### Goal
Expand volume arcs into chapter cards.

### Output requirements
- chapter goal
- conflict progression
- new information
- chapter hook

---

## Agent B7: SceneOutliner

### Goal
Expand chapter cards into scene cards (3-6 scenes per chapter by default).

### Output requirements
- scene goal
- obstacles
- twist
- result
- writeback candidates

---

## Agent B8: SceneWriter

### Goal
Write one scene only.

### Required input bundle
- latest approved `StoryBible`
- `ChapterOutline` and current `SceneOutline`
- latest `MemorySnapshot`
- style constraints

### Output
- `DraftBundle` with `status = draft`

---

## Agent B9: ContinuityAuditor

### Goal
Detect structural risks before publish.

### Checks
- world rule conflicts
- character knowledge leakage
- timeline mismatch
- power scaling break
- unresolved scene objective

### Output
- `ReviewReport`

Decision policy:
- critical issue -> `required_rewrite`
- high issue count >= 3 -> `revise`
- otherwise -> `pass`

---

## Agent B10: StyleEditor

### Goal
Polish expression without changing fact layer.

### Constraints
- no new canonical facts
- no retroactive rule changes
- preserve scene objective/outcome

Output:
- updated `DraftBundle` with `status = revised`

---

## Agent B11: MemoryWriter

### Goal
Extract factual deltas from approved draft and write memory events.

### Output
- `WritebackEvent`

Required extraction:
- facts_added
- character_state_changes
- foreshadow_updates

Hard check:
- if review decision != `pass`, reject writeback.

---

## Agent B12: Orchestrator

### Goal
Run state machine with retries and stop gates.

### Core sequence

1. topic generation
2. topic evaluation/selection
3. story bible
4. master outline
5. volume outline
6. chapter outline
7. scene outline
8. scene draft
9. review
10. style edit (optional)
11. memory writeback
12. next scene/chapter

### Retry policy
- generation errors: retry up to 2 times
- review block: must revise before advancing
- unresolved critical issue: halt run

