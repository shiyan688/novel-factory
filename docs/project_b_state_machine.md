# Project B State Machine (v1)

This state machine governs autonomous production from topic ideation to memory writeback.

## Flow

1. `PROJECT_INITIALIZED`
2. `TOPIC_GENERATED`
3. `TOPIC_SELECTED`
4. `BIBLE_GENERATED`
5. `MASTER_OUTLINE_GENERATED`
6. `VOLUME_OUTLINE_GENERATED`
7. `CHAPTER_OUTLINE_GENERATED`
8. `SCENE_OUTLINE_GENERATED`
9. `SCENE_DRAFT_GENERATED`
10. `REVIEW_COMPLETED`
11. `STYLE_EDITED` (optional)
12. `MEMORY_WRITTEN`
13. `NEXT_SCENE_OR_CHAPTER`
14. `PROJECT_COMPLETED`

Failure transition:

- Any state -> `FAILED`

## Pass criteria by state

## `TOPIC_GENERATED`
- At least `top_k` ideas generated.
- Every idea has hook/serial/differentiation scores.

## `TOPIC_SELECTED`
- Exactly one idea marked selected.
- Selection rationale stored.

## `BIBLE_GENERATED`
- StoryBible contains:
  - story DNA
  - world rules
  - character bible
  - hard constraints
  - ending direction
- No direct contradiction among hard constraints.

## `MASTER_OUTLINE_GENERATED`
- Must answer:
  - mainline question
  - act structure
  - ending route

## `VOLUME_OUTLINE_GENERATED`
- Each volume has goal, core enemy, climax, ending hook.
- Arc order has no gaps.

## `CHAPTER_OUTLINE_GENERATED`
- Every chapter has:
  - goal
  - conflict progression
  - hook

## `SCENE_OUTLINE_GENERATED`
- Every scene has:
  - objective
  - obstacle
  - state change
  - writeback candidate

## `SCENE_DRAFT_GENERATED`
- Draft generated from approved inputs only:
  - latest story bible
  - outline node
  - memory snapshot

## `REVIEW_COMPLETED`
- Review score object exists.
- If decision is `required_rewrite`, pipeline cannot advance.

## `STYLE_EDITED`
- Optional stage.
- Fact layer unchanged (only expression layer modified).

## `MEMORY_WRITTEN`
- Writeback event persisted.
- Facts inserted into memory ledger with visibility + confidence.
- Foreshadow status updated when needed.

## `NEXT_SCENE_OR_CHAPTER`
- Scheduler picks next scene by outline order.
- If chapter scenes finished, advance chapter.
- If volume finished, advance volume.

## Global stop rules

- Stop run immediately when:
  - unresolved critical continuity issue exists
  - story bible hard rule is violated
  - memory writeback fails schema validation

## Retry policy

- Generation service transient error: retry <= 2
- Review blocked by high issues: force revise and re-review
- Writeback failure: halt and require manual intervention

