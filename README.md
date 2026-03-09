# NovelFactory Workflow Package (Project A First)

This repository now contains the executable baseline for the **book deconstruction workflow** (Project A), with a shared contract that is directly compatible with Project B.

## Documentation

- Full Chinese usage guide: `docs/usage_guide_zh.md`

## What is included

- `shared-schema/v1/`: canonical JSON Schemas shared by Project A and Project B.
- `sql/project_a_schema_v1.sql`: PostgreSQL schema draft for deconstruction + pattern library.
- `sql/project_b_schema_v1.sql`: PostgreSQL schema draft for autonomous planning/writing/review/writeback.
- `api/project_a_openapi_v1.yaml`: OpenAPI v1 contract for Project A services.
- `api/project_b_openapi_v1.yaml`: OpenAPI v1 contract for Project B services.
- `prompts/project_a_agents.md`: agent/prompt spec for extraction and quality loops.
- `prompts/project_b_agents.md`: agent/prompt spec for planning/writing/review/writeback loops.
- `docs/project_a_state_machine.md`: state machine and pass criteria for autonomous processing.
- `docs/project_b_state_machine.md`: state machine and pass criteria for autonomous generation.
- `docs/integration_contract_v1.md`: A->B handoff contract and compatibility rules.
- `docs/project_a_plan.md`: detailed project plan for Project A.
- `docs/project_b_plan.md`: detailed project plan for Project B.

## Goal of this package

Turn source novels into reusable structured assets:

1. `BookModelPack`
2. `PatternLibraryItem`
3. `GenrePatternPack`
4. `StyleProfile`

These outputs are normalized to `schema_version = "v1"` and can be consumed directly by downstream planning/writing services.

Project B then consumes those assets to produce:

1. `TopicIdea`
2. `StoryBible`
3. `OutlinePack`
4. `DraftBundle`
5. `ReviewReport`
6. `WritebackEvent`

## Suggested execution order

1. Apply SQL schema in PostgreSQL.
2. Implement APIs from OpenAPI.
3. Run extraction jobs with the prompt specs.
4. Export `BookModelPack` and `GenrePatternPack` for Project B.
5. Run Project B pipeline from topic generation to memory writeback.
