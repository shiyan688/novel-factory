# Project A State Machine (v1)

This state machine defines the autonomous deconstruction flow and pass criteria.

## Flow

1. `INIT`
2. `IMPORTED`
3. `SEGMENTED`
4. `EXTRACTED_CHAPTERS`
5. `EXTRACTED_SCENES`
6. `EXTRACTED_CHARACTERS`
7. `EXTRACTED_WORLD_RULES`
8. `EXTRACTED_FORESHADOW`
9. `PROFILED_STYLE`
10. `MINED_PATTERNS`
11. `QA_REVIEW`
12. `EXPORTED_MODEL_PACK`
13. `DONE`

Failure transition:

- Any state -> `FAILED` (with retry policy and error reason)

## Pass criteria by state

## `IMPORTED`
- Source file is normalized.
- `book_id` created.
- Initial record exists in `books`.

## `SEGMENTED`
- Chapter segmentation coverage >= 99% text.
- Scene segmentation confidence average >= 0.75.

## `EXTRACTED_CHAPTERS`
- Every chapter has:
  - `chapter_goal`
  - `conflict`
  - `result`
  - `hook`
- Missing key fields <= 5%.

## `EXTRACTED_SCENES`
- Every scene has:
  - `scene_goal`
  - `obstacles`
  - `result`
- Invalid scene order = 0.

## `EXTRACTED_CHARACTERS`
- Main character recall >= 0.90 (QA sample).
- Relation graph has no broken character references.

## `EXTRACTED_WORLD_RULES`
- Rules with `confidence >= 0.7` are validated by QA.
- Contradictory rules are flagged before next state.

## `EXTRACTED_FORESHADOW`
- Each pair has setup reference.
- Status is one of `planted|partially_paid|paid|abandoned`.

## `PROFILED_STYLE`
- Style metrics available:
  - dialogue density
  - sentence length
  - twist frequency
  - hook strength

## `MINED_PATTERNS`
- Pattern entries have:
  - type
  - input slots
  - expected output
  - constraints
- Top patterns pass manual sample review >= 80%.

## `QA_REVIEW`
- All `high` and `critical` issues resolved or accepted.
- Export lock is denied when unresolved critical issues exist.

## `EXPORTED_MODEL_PACK`
- `BookModelPack` validated against JSON Schema v1.
- All IDs satisfy prefixed pattern rules.

## Retry policy

- Auto retry: up to 2 times for transient model/service failures.
- Manual intervention required after 2 failures.
- Retry always writes an audit entry in `extraction_jobs` and `qa_reviews`.

