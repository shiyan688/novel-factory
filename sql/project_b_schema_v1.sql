-- Project B: Autonomous Planning/Writing/Review/Writeback Engine
-- Target: PostgreSQL 15+
-- Schema version: v1

BEGIN;

CREATE TABLE IF NOT EXISTS projects (
    project_id TEXT PRIMARY KEY CHECK (project_id ~ '^proj_[A-Za-z0-9_-]+$'),
    title_working TEXT NOT NULL,
    genre TEXT[] NOT NULL,
    target_platform TEXT NOT NULL,
    audience TEXT[] NOT NULL,
    target_length_words INT NOT NULL DEFAULT 0 CHECK (target_length_words >= 0),
    volume_count INT NOT NULL DEFAULT 0 CHECK (volume_count >= 0),
    status TEXT NOT NULL DEFAULT 'initialized' CHECK (
        status IN (
            'initialized',
            'topic_selecting',
            'bible_ready',
            'outline_ready',
            'writing',
            'paused',
            'completed',
            'failed'
        )
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_genre_gin ON projects USING GIN (genre);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects (status);

CREATE TABLE IF NOT EXISTS project_constraints (
    constraint_id TEXT PRIMARY KEY CHECK (constraint_id ~ '^pc_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    constraint_type TEXT NOT NULL CHECK (constraint_type IN ('forbidden_element', 'must_have', 'style_guardrail', 'hard_rule')),
    constraint_value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_project_constraints_project ON project_constraints (project_id);

CREATE TABLE IF NOT EXISTS topic_ideas (
    idea_id TEXT PRIMARY KEY CHECK (idea_id ~ '^idea_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    logline TEXT NOT NULL,
    genre TEXT[] NOT NULL,
    selling_points TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    risk_flags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    score_hook NUMERIC(4,2) NOT NULL DEFAULT 0 CHECK (score_hook >= 0 AND score_hook <= 10),
    score_serial_potential NUMERIC(4,2) NOT NULL DEFAULT 0 CHECK (score_serial_potential >= 0 AND score_serial_potential <= 10),
    score_differentiation NUMERIC(4,2) NOT NULL DEFAULT 0 CHECK (score_differentiation >= 0 AND score_differentiation <= 10),
    total_score NUMERIC(5,2) GENERATED ALWAYS AS (score_hook + score_serial_potential + score_differentiation) STORED,
    rank_no INT,
    selected BOOLEAN NOT NULL DEFAULT FALSE,
    source_pattern_pack_refs TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_topic_ideas_project ON topic_ideas (project_id);
CREATE INDEX IF NOT EXISTS idx_topic_ideas_selected ON topic_ideas (selected);
CREATE INDEX IF NOT EXISTS idx_topic_ideas_rank ON topic_ideas (project_id, rank_no);

CREATE TABLE IF NOT EXISTS story_bibles (
    story_bible_id TEXT PRIMARY KEY CHECK (story_bible_id ~ '^sb_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    idea_id TEXT REFERENCES topic_ideas(idea_id) ON DELETE SET NULL,
    story_dna JSONB NOT NULL,
    world_bible JSONB NOT NULL,
    character_bible JSONB NOT NULL DEFAULT '[]'::jsonb,
    hard_constraints JSONB NOT NULL DEFAULT '[]'::jsonb,
    ending_direction TEXT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'archived')),
    version_no INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_story_bibles_project_version ON story_bibles (project_id, version_no);
CREATE INDEX IF NOT EXISTS idx_story_bibles_project_status ON story_bibles (project_id, status);

CREATE TABLE IF NOT EXISTS outlines (
    outline_id TEXT PRIMARY KEY CHECK (outline_id ~ '^out_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    story_bible_id TEXT REFERENCES story_bibles(story_bible_id) ON DELETE SET NULL,
    level TEXT NOT NULL CHECK (level IN ('master', 'volume', 'chapter', 'scene')),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'archived')),
    version_no INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outlines_project_level ON outlines (project_id, level);
CREATE INDEX IF NOT EXISTS idx_outlines_story_bible ON outlines (story_bible_id);

CREATE TABLE IF NOT EXISTS master_outlines (
    master_outline_id TEXT PRIMARY KEY CHECK (master_outline_id ~ '^mout_[A-Za-z0-9_-]+$'),
    outline_id TEXT NOT NULL REFERENCES outlines(outline_id) ON DELETE CASCADE,
    mainline TEXT NOT NULL,
    act_structure TEXT NOT NULL,
    volume_themes JSONB NOT NULL DEFAULT '[]'::jsonb,
    major_turning_points JSONB NOT NULL DEFAULT '[]'::jsonb,
    ending_route TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_master_outlines_outline ON master_outlines (outline_id);

CREATE TABLE IF NOT EXISTS volume_outlines (
    volume_outline_id TEXT PRIMARY KEY CHECK (volume_outline_id ~ '^vout_[A-Za-z0-9_-]+$'),
    outline_id TEXT NOT NULL REFERENCES outlines(outline_id) ON DELETE CASCADE,
    arc_id TEXT NOT NULL CHECK (arc_id ~ '^arc_[A-Za-z0-9_-]+$'),
    arc_order INT NOT NULL,
    title TEXT NOT NULL,
    opening_state TEXT NOT NULL,
    goal TEXT NOT NULL,
    core_enemy TEXT NOT NULL,
    mid_misjudgment TEXT NOT NULL,
    climax TEXT NOT NULL,
    ending_hook TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_volume_outlines_unique_order ON volume_outlines (outline_id, arc_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_volume_outlines_unique_arc ON volume_outlines (outline_id, arc_id);

CREATE TABLE IF NOT EXISTS chapter_outlines (
    chapter_outline_id TEXT PRIMARY KEY CHECK (chapter_outline_id ~ '^cout_[A-Za-z0-9_-]+$'),
    outline_id TEXT NOT NULL REFERENCES outlines(outline_id) ON DELETE CASCADE,
    chapter_id TEXT NOT NULL CHECK (chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    volume_id TEXT NOT NULL CHECK (volume_id ~ '^arc_[A-Za-z0-9_-]+$'),
    chapter_order INT NOT NULL,
    title TEXT,
    chapter_goal TEXT NOT NULL,
    plot_function TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    pov_character TEXT,
    entry_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    key_beats JSONB NOT NULL DEFAULT '[]'::jsonb,
    exit_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_chapter_outlines_unique_order ON chapter_outlines (outline_id, chapter_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_chapter_outlines_unique_chapter ON chapter_outlines (outline_id, chapter_id);

CREATE TABLE IF NOT EXISTS scene_outlines (
    scene_outline_id TEXT PRIMARY KEY CHECK (scene_outline_id ~ '^sout_[A-Za-z0-9_-]+$'),
    outline_id TEXT NOT NULL REFERENCES outlines(outline_id) ON DELETE CASCADE,
    scene_id TEXT NOT NULL CHECK (scene_id ~ '^sc_[A-Za-z0-9_-]+$'),
    chapter_id TEXT NOT NULL CHECK (chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    scene_order INT NOT NULL,
    scene_goal TEXT NOT NULL,
    location TEXT,
    participants TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    conflict_type TEXT,
    obstacles TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    twist TEXT,
    result TEXT,
    memory_writeback_candidates JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_scene_outlines_unique_order ON scene_outlines (outline_id, chapter_id, scene_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_scene_outlines_unique_scene ON scene_outlines (outline_id, scene_id);

CREATE TABLE IF NOT EXISTS draft_bundles (
    draft_id TEXT PRIMARY KEY CHECK (draft_id ~ '^draft_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    story_bible_id TEXT REFERENCES story_bibles(story_bible_id) ON DELETE SET NULL,
    outline_id TEXT REFERENCES outlines(outline_id) ON DELETE SET NULL,
    chapter_id TEXT NOT NULL CHECK (chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    scene_id TEXT NOT NULL CHECK (scene_id ~ '^sc_[A-Za-z0-9_-]+$'),
    memory_snapshot_id TEXT NOT NULL CHECK (memory_snapshot_id ~ '^memsnap_[A-Za-z0-9_-]+$'),
    draft_text TEXT NOT NULL,
    style_applied JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'revised', 'approved')),
    revision_no INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_draft_bundles_project ON draft_bundles (project_id);
CREATE INDEX IF NOT EXISTS idx_draft_bundles_scene ON draft_bundles (project_id, chapter_id, scene_id);
CREATE INDEX IF NOT EXISTS idx_draft_bundles_status ON draft_bundles (status);

CREATE TABLE IF NOT EXISTS review_reports (
    review_id TEXT PRIMARY KEY CHECK (review_id ~ '^review_[A-Za-z0-9_-]+$'),
    draft_id TEXT NOT NULL REFERENCES draft_bundles(draft_id) ON DELETE CASCADE,
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    scores JSONB NOT NULL,
    decision TEXT NOT NULL CHECK (decision IN ('pass', 'revise', 'required_rewrite')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_review_reports_draft ON review_reports (draft_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_project ON review_reports (project_id);

CREATE TABLE IF NOT EXISTS review_issues (
    issue_id TEXT PRIMARY KEY CHECK (issue_id ~ '^ri_[A-Za-z0-9_-]+$'),
    review_id TEXT NOT NULL REFERENCES review_reports(review_id) ON DELETE CASCADE,
    issue_type TEXT NOT NULL CHECK (
        issue_type IN (
            'continuity',
            'character_consistency',
            'timeline',
            'power_scaling',
            'style_drift',
            'hook_weakness'
        )
    ),
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    location TEXT NOT NULL,
    description TEXT NOT NULL,
    fix_suggestion TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_review_issues_review ON review_issues (review_id);
CREATE INDEX IF NOT EXISTS idx_review_issues_severity ON review_issues (severity);

CREATE TABLE IF NOT EXISTS memory_snapshots (
    memory_snapshot_id TEXT PRIMARY KEY CHECK (memory_snapshot_id ~ '^memsnap_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    snapshot_scope TEXT NOT NULL CHECK (snapshot_scope IN ('chapter', 'scene', 'manual')),
    based_on_chapter_id TEXT CHECK (based_on_chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    snapshot_payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_memory_snapshots_project ON memory_snapshots (project_id);

CREATE TABLE IF NOT EXISTS memory_ledger (
    memory_fact_id TEXT PRIMARY KEY CHECK (memory_fact_id ~ '^mem_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    chapter_id TEXT CHECK (chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    scene_id TEXT CHECK (scene_id ~ '^sc_[A-Za-z0-9_-]+$'),
    fact_type TEXT NOT NULL CHECK (fact_type IN ('world_fact', 'character_fact', 'timeline_fact', 'resource_fact')),
    subject TEXT NOT NULL,
    predicate TEXT NOT NULL,
    confidence NUMERIC(4,3) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    visibility TEXT NOT NULL CHECK (visibility IN ('reader_known', 'character_known', 'hidden')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'superseded', 'revoked')),
    source_draft_id TEXT REFERENCES draft_bundles(draft_id) ON DELETE SET NULL,
    source_review_id TEXT REFERENCES review_reports(review_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_memory_ledger_project ON memory_ledger (project_id);
CREATE INDEX IF NOT EXISTS idx_memory_ledger_fact_type ON memory_ledger (fact_type);
CREATE INDEX IF NOT EXISTS idx_memory_ledger_visibility ON memory_ledger (visibility);

CREATE TABLE IF NOT EXISTS writeback_events (
    memory_event_id TEXT PRIMARY KEY CHECK (memory_event_id ~ '^memevt_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    draft_id TEXT NOT NULL REFERENCES draft_bundles(draft_id) ON DELETE CASCADE,
    review_id TEXT NOT NULL REFERENCES review_reports(review_id) ON DELETE CASCADE,
    chapter_id TEXT NOT NULL CHECK (chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    scene_id TEXT NOT NULL CHECK (scene_id ~ '^sc_[A-Za-z0-9_-]+$'),
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_writeback_events_project ON writeback_events (project_id);
CREATE INDEX IF NOT EXISTS idx_writeback_events_draft ON writeback_events (draft_id);

CREATE TABLE IF NOT EXISTS pipeline_runs (
    run_id TEXT PRIMARY KEY CHECK (run_id ~ '^run_[A-Za-z0-9_-]+$'),
    project_id TEXT NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    current_state TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'paused', 'success', 'failed', 'canceled')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pipeline_runs_project ON pipeline_runs (project_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_status ON pipeline_runs (status);

CREATE TABLE IF NOT EXISTS pipeline_run_steps (
    step_id TEXT PRIMARY KEY CHECK (step_id ~ '^step_[A-Za-z0-9_-]+$'),
    run_id TEXT NOT NULL REFERENCES pipeline_runs(run_id) ON DELETE CASCADE,
    step_name TEXT NOT NULL,
    step_order INT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'success', 'failed', 'skipped')),
    input_refs JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_refs JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_message TEXT,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pipeline_steps_unique_order ON pipeline_run_steps (run_id, step_order);
CREATE INDEX IF NOT EXISTS idx_pipeline_steps_status ON pipeline_run_steps (status);

COMMIT;

