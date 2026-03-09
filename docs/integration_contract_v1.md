# Integration Contract v1 (Project A <-> Project B)

This contract guarantees that Project A outputs are directly consumable by Project B.

## Producer/Consumer boundary

- Project A produces:
  - `BookModelPack`
  - `PatternLibraryItem`
  - `GenrePatternPack`
  - `StyleProfile`
- Project B consumes those assets and produces:
  - `StoryBible`
  - `OutlinePack`
  - `DraftBundle`
  - `ReviewReport`
  - `WritebackEvent`

## Non-negotiable compatibility rules

1. Shared metadata fields:
   - `schema_version = "v1"`
   - `producer`
   - `created_at`
   - `updated_at`
2. ID prefix rules from `shared-schema/v1/common.schema.json` are mandatory.
3. Enum values are frozen in v1 and must not drift across projects.
4. New fields must be backward-compatible and versioned.
5. Project A exposes structural data only. No long raw text dependency in downstream APIs.

## Hand-off mapping

- A.`BookModelPack.story_dna` -> B.`StoryBible.story_dna`
- A.`BookModelPack.style_profile` -> B.`style_profile_ref` selection source
- A.`PatternLibraryItem` -> B.`topic generation`, `outline generation` retrieval
- A.`foreshadow_payoff_pairs` structure -> B.`WritebackEvent.foreshadow_updates` structure

## API-level dependency

- Project B calls:
  - `GET /v1/books/{book_id}/model-pack`
  - `POST /v1/patterns/search`
  - `GET /v1/genres/{genre}/pattern-pack`

- Project B exposes for downstream publish/control systems:
  - `POST /v1/topic-ideas/generate`
  - `POST /v1/story-bibles/generate`
  - `POST /v1/outlines/*/generate`
  - `POST /v1/drafts/generate`
  - `POST /v1/reviews/run`
  - `POST /v1/memory/writeback`

## Event-level dependency

- Optional event contract:
  - `book.modeled.v1`
  - `pattern.pack.updated.v1`
- Recommended payload keys:
  - `schema_version`
  - `book_id` or `genre_pack_id`
  - `created_at`

## Versioning strategy

- `v1` is schema-locked.
- Breaking changes require `v2` endpoints and `schema_version = "v2"`.
- Additive changes in `v1` require defaults and backward-compat notes.
