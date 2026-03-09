# Project B Detailed Plan (Autonomous Planning -> Draft -> Review -> Writeback)

## 1. Objective

Build an autonomous production engine that consumes Project A assets and outputs publish-ready chapter drafts with verified continuity and memory writeback.

Primary outputs:
- `TopicIdea`
- `StoryBible`
- `OutlinePack`
- `DraftBundle`
- `ReviewReport`
- `WritebackEvent`

## 2. Scope

In scope:
- topic generation/evaluation
- story bible generation
- multi-level outline expansion
- scene-level drafting
- continuity and style review
- memory ledger writeback
- state-machine orchestration

Out of scope:
- source novel import/deconstruction
- pattern mining from raw corpus

## 3. Milestones

## Milestone 1 (Week 1-2): Contract + base services
- shared schema binding for B objects
- project management APIs
- basic orchestrator skeleton

Acceptance:
- create project and run a dry pipeline with mock steps.

## Milestone 2 (Week 3-4): Topic + StoryBible
- topic generation and ranking
- topic select endpoint
- story bible generation with hard-rule validator

Acceptance:
- from constraints to approved story bible in one run.

## Milestone 3 (Week 5-7): Outline hierarchy
- master/volume/chapter/scene outline generators
- consistency checks across levels

Acceptance:
- scene outlines trace back to chapter and volume goals.

## Milestone 4 (Week 8-10): Scene drafting + review
- scene draft generation service
- continuity auditor and style editor
- rewrite loop policy

Acceptance:
- critical review issues block advancement correctly.

## Milestone 5 (Week 11-13): Memory writeback + snapshots
- writeback extraction from approved drafts
- memory ledger and snapshot builder
- foreshadow lifecycle updates

Acceptance:
- next scene generation can consume latest memory snapshot.

## Milestone 6 (Week 14-15): End-to-end stabilization
- full pipeline e2e tests
- failure retry behavior
- human override points

Acceptance:
- one full arc runs from topic to memory-updated drafts.

## 4. Work breakdown

Backend:
- API implementation
- orchestration and persistence
- snapshot and writeback transaction guarantees

LLM/Prompt:
- topic/bible/outline/draft prompt specs
- deterministic JSON outputs
- policy gates for review and rewrite

QA:
- continuity benchmark set
- writeback precision sampling
- regression checks for style drift

## 5. Risks and mitigations

Risk: outline drift over long runs  
Mitigation: strict parent-child outline checks at each level

Risk: world-rule inconsistency in drafts  
Mitigation: pre-draft rule injection + post-draft continuity audit

Risk: memory ledger pollution  
Mitigation: confidence threshold + supersede/revoke lifecycle

## 6. KPI baseline

- outline hierarchy consistency >= 85%
- critical continuity interception >= 90%
- approved draft writeback precision >= 85%
- scene-level generation pass rate >= 80%

## 7. Dependency contract with Project A

- consume:
  - `POST /v1/patterns/search`
  - `GET /v1/genres/{genre}/pattern-pack`
  - `GET /v1/books/{book_id}/model-pack` (reference assets)
- maintain enum and ID compatibility via `shared-schema/v1`.

