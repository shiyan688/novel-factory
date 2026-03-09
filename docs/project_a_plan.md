# Project A Detailed Plan (Deconstruction + Outline DB)

## 1. Objective

Build a production-ready pipeline to transform novels into reusable narrative assets.

Primary outputs:
- `BookModelPack`
- `PatternLibraryItem`
- `GenrePatternPack`
- `StyleProfile`

## 2. Scope

In scope:
- source import and normalization
- chapter/scene/character/world/foreshadow/style extraction
- pattern mining and retrieval APIs
- QA and export gate

Out of scope:
- new story generation
- long-form drafting
- writing-time memory writeback (owned by Project B)

## 3. Milestones

## Milestone 1 (Week 1-2): Foundation
- shared schema finalization (`shared-schema/v1`)
- PostgreSQL schema setup (`sql/project_a_schema_v1.sql`)
- ingestion APIs skeleton (`/v1/source-books/import`)

Acceptance:
- import one book and create queued extraction job.

## Milestone 2 (Week 3-5): Structural extraction MVP
- segmentation service
- chapter + scene extraction agents
- extraction job orchestration

Acceptance:
- output complete chapter/scene records for test corpus.

## Milestone 3 (Week 6-8): Entity and rule modeling
- character/relations extraction
- world rule extraction
- foreshadow-payoff mapping

Acceptance:
- no broken references across chapters/scenes/characters.

## Milestone 4 (Week 9-11): Style and patterns
- style profiling
- pattern mining and indexing
- genre pattern pack build

Acceptance:
- support pattern search API with meaningful top-k results.

## Milestone 5 (Week 12-13): QA and export
- QA review loop
- BookModelPack export endpoint
- integration contract verification with Project B mock consumer

Acceptance:
- schema-valid model pack export and stable API contract.

## 4. Work breakdown

Backend:
- API service and job orchestration
- persistence and query optimization
- export + retrieval endpoints

LLM/Extraction:
- agent prompts and deterministic JSON outputs
- confidence calibration
- pattern generalization

QA/Data:
- annotation sampling
- high-risk issue policy
- acceptance dashboard

## 5. Risks and mitigations

Risk: unstable scene segmentation  
Mitigation: hybrid rule-first + model-correction strategy

Risk: shallow pattern quality  
Mitigation: slot-based abstraction and QA threshold before publish

Risk: schema drift across projects  
Mitigation: single shared schema folder and version lock checks in CI

## 6. KPI baseline

- chapter split accuracy >= 95%
- major character recall >= 90%
- high-confidence extraction precision >= 85%
- pattern retrieval satisfaction >= 80%

## 7. Handoff readiness checklist

- `BookModelPack` passes JSON Schema validation
- pattern API supports `genre + pattern_type + constraints`
- `GenrePatternPack` available for at least one target genre
- OpenAPI published and frozen for v1

