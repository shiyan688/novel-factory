# Shared Schema v1

This folder defines canonical contracts used by both project tracks.

## Core files

- `common.schema.json`: IDs, metadata, and enum definitions.
- `book-model-pack.schema.json`: primary output of Project A.
- `pattern-library-item.schema.json`: reusable narrative pattern unit.
- `genre-pattern-pack.schema.json`: genre-level pattern bundle.
- `style-profile.schema.json`: style metrics profile.
- `topic-idea.schema.json`: Project B candidate topic object.
- `story-bible.schema.json`: Project B narrative constitution object.
- `outline-pack.schema.json`: multi-level outline object.
- `draft-bundle.schema.json`: scene-level draft package.
- `review-report.schema.json`: audit output for draft quality gates.
- `memory-writeback-event.schema.json`: writeback format used by Project B and compatible with Project A fact structure.

## Compatibility rules

- Every payload must include:
  - `metadata.schema_version = "v1"`
  - `metadata.producer`
  - `metadata.created_at`
  - `metadata.updated_at`
- IDs must follow prefixed string patterns in `common.schema.json`.
- Unknown fields are not allowed unless the schema explicitly permits them.
