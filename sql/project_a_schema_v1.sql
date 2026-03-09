-- Project A: Deconstruction + Outline Database
-- Target: PostgreSQL 15+
-- Schema version: v1

BEGIN;

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS books (
    book_id TEXT PRIMARY KEY CHECK (book_id ~ '^book_[A-Za-z0-9_-]+$'),
    title TEXT NOT NULL,
    source_type TEXT NOT NULL CHECK (source_type IN ('txt', 'docx', 'epub', 'markdown', 'json')),
    content_ref TEXT NOT NULL,
    language_code TEXT NOT NULL DEFAULT 'zh-CN',
    genre TEXT[] NOT NULL,
    author_name TEXT,
    story_dna JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'imported' CHECK (status IN ('imported', 'extracting', 'modeled', 'failed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_books_genre_gin ON books USING GIN (genre);
CREATE INDEX IF NOT EXISTS idx_books_status ON books (status);

CREATE TABLE IF NOT EXISTS book_segments (
    segment_id TEXT PRIMARY KEY CHECK (segment_id ~ '^seg_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    chapter_no INT,
    scene_no INT,
    start_offset INT NOT NULL,
    end_offset INT NOT NULL,
    text_clean TEXT NOT NULL,
    scene_cut_confidence NUMERIC(4,3) DEFAULT 0.0 CHECK (scene_cut_confidence >= 0 AND scene_cut_confidence <= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_segments_book ON book_segments (book_id);
CREATE INDEX IF NOT EXISTS idx_segments_book_ch_scene ON book_segments (book_id, chapter_no, scene_no);

CREATE TABLE IF NOT EXISTS arcs (
    arc_id TEXT PRIMARY KEY CHECK (arc_id ~ '^arc_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    arc_order INT NOT NULL,
    title TEXT NOT NULL,
    goal TEXT,
    obstacle TEXT,
    turning_point TEXT,
    climax TEXT,
    next_hook TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_arcs_unique_order ON arcs (book_id, arc_order);

CREATE TABLE IF NOT EXISTS chapters (
    chapter_id TEXT PRIMARY KEY CHECK (chapter_id ~ '^ch_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    arc_id TEXT REFERENCES arcs(arc_id) ON DELETE SET NULL,
    chapter_no INT NOT NULL,
    title TEXT,
    pov_character_id TEXT,
    chapter_goal TEXT,
    conflict TEXT,
    turning_point TEXT,
    result TEXT,
    hook TEXT,
    entry_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    exit_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    extraction_confidence NUMERIC(4,3) DEFAULT 0.0 CHECK (extraction_confidence >= 0 AND extraction_confidence <= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_chapters_book_no ON chapters (book_id, chapter_no);
CREATE INDEX IF NOT EXISTS idx_chapters_arc ON chapters (arc_id);

CREATE TABLE IF NOT EXISTS scenes (
    scene_id TEXT PRIMARY KEY CHECK (scene_id ~ '^sc_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    chapter_id TEXT NOT NULL REFERENCES chapters(chapter_id) ON DELETE CASCADE,
    scene_no INT NOT NULL,
    location TEXT,
    scene_goal TEXT,
    obstacles TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    twist TEXT,
    result TEXT,
    emotional_shift TEXT,
    information_delta JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_foreshadow_setup BOOLEAN NOT NULL DEFAULT FALSE,
    is_mainline_progress BOOLEAN NOT NULL DEFAULT FALSE,
    extraction_confidence NUMERIC(4,3) DEFAULT 0.0 CHECK (extraction_confidence >= 0 AND extraction_confidence <= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_scenes_chapter_no ON scenes (chapter_id, scene_no);
CREATE INDEX IF NOT EXISTS idx_scenes_book ON scenes (book_id);

CREATE TABLE IF NOT EXISTS characters (
    character_id TEXT PRIMARY KEY CHECK (character_id ~ '^char_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT,
    public_persona TEXT,
    hidden_motive TEXT,
    short_term_goals TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    long_term_goals TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    weakness TEXT,
    arc_summary TEXT,
    power_curve JSONB NOT NULL DEFAULT '{}'::jsonb,
    first_seen_chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    last_seen_chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_characters_book ON characters (book_id);
CREATE INDEX IF NOT EXISTS idx_characters_name ON characters (name);

CREATE TABLE IF NOT EXISTS character_relations (
    relation_id TEXT PRIMARY KEY CHECK (relation_id ~ '^rel_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    source_character_id TEXT NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    target_character_id TEXT NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    relation_type TEXT NOT NULL,
    relation_state TEXT,
    intensity NUMERIC(4,3) DEFAULT 0.5 CHECK (intensity >= 0 AND intensity <= 1),
    evidence_chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (source_character_id <> target_character_id)
);

CREATE INDEX IF NOT EXISTS idx_relations_book ON character_relations (book_id);
CREATE INDEX IF NOT EXISTS idx_relations_pair ON character_relations (source_character_id, target_character_id);

CREATE TABLE IF NOT EXISTS world_rules (
    rule_id TEXT PRIMARY KEY CHECK (rule_id ~ '^rule_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    domain TEXT NOT NULL,
    rule_text TEXT NOT NULL,
    resource_binding TEXT,
    cost TEXT,
    violation_penalty TEXT,
    narrative_trigger TEXT,
    first_seen_chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    confidence NUMERIC(4,3) DEFAULT 0.0 CHECK (confidence >= 0 AND confidence <= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_world_rules_book ON world_rules (book_id);
CREATE INDEX IF NOT EXISTS idx_world_rules_domain ON world_rules (domain);

CREATE TABLE IF NOT EXISTS foreshadow_pairs (
    foreshadow_id TEXT PRIMARY KEY CHECK (foreshadow_id ~ '^fo_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    setup_scene_id TEXT REFERENCES scenes(scene_id) ON DELETE SET NULL,
    setup_chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    setup_summary TEXT NOT NULL,
    payoff_scene_id TEXT REFERENCES scenes(scene_id) ON DELETE SET NULL,
    payoff_chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    payoff_summary TEXT,
    payoff_strength NUMERIC(4,3) DEFAULT 0.0 CHECK (payoff_strength >= 0 AND payoff_strength <= 1),
    status TEXT NOT NULL DEFAULT 'planted' CHECK (status IN ('planted', 'partially_paid', 'paid', 'abandoned')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_foreshadow_book ON foreshadow_pairs (book_id);
CREATE INDEX IF NOT EXISTS idx_foreshadow_status ON foreshadow_pairs (status);

CREATE TABLE IF NOT EXISTS style_profiles (
    style_id TEXT PRIMARY KEY CHECK (style_id ~ '^style_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    tone TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    dialogue_density NUMERIC(5,4) NOT NULL DEFAULT 0.0 CHECK (dialogue_density >= 0 AND dialogue_density <= 1),
    avg_sentence_length NUMERIC(8,3) NOT NULL DEFAULT 0.0,
    twist_frequency_per_10k NUMERIC(8,3) NOT NULL DEFAULT 0.0,
    hook_strength NUMERIC(4,2) NOT NULL DEFAULT 0.0 CHECK (hook_strength >= 0 AND hook_strength <= 10),
    info_release_rate NUMERIC(8,3) NOT NULL DEFAULT 0.0,
    action_density NUMERIC(5,4) NOT NULL DEFAULT 0.0 CHECK (action_density >= 0 AND action_density <= 1),
    sample_size_tokens INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_style_profiles_book ON style_profiles (book_id);

CREATE TABLE IF NOT EXISTS pattern_library (
    pattern_id TEXT PRIMARY KEY CHECK (pattern_id ~ '^pat_[A-Za-z0-9_-]+$'),
    pattern_type TEXT NOT NULL CHECK (
        pattern_type IN (
            'opening_hook',
            'mid_twist',
            'chapter_cliffhanger',
            'power_escalation',
            'faction_conflict',
            'relationship_push',
            'foreshadow_setup',
            'foreshadow_payoff'
        )
    ),
    genre TEXT[] NOT NULL,
    summary TEXT NOT NULL,
    input_slots JSONB NOT NULL DEFAULT '{}'::jsonb,
    expected_output JSONB NOT NULL DEFAULT '{}'::jsonb,
    constraints JSONB NOT NULL DEFAULT '[]'::jsonb,
    quality_score NUMERIC(4,3) DEFAULT 0.0 CHECK (quality_score >= 0 AND quality_score <= 1),
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patterns_type ON pattern_library (pattern_type);
CREATE INDEX IF NOT EXISTS idx_patterns_genre_gin ON pattern_library USING GIN (genre);

CREATE TABLE IF NOT EXISTS pattern_book_refs (
    ref_id TEXT PRIMARY KEY CHECK (ref_id ~ '^pref_[A-Za-z0-9_-]+$'),
    pattern_id TEXT NOT NULL REFERENCES pattern_library(pattern_id) ON DELETE CASCADE,
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    chapter_id TEXT REFERENCES chapters(chapter_id) ON DELETE SET NULL,
    scene_id TEXT REFERENCES scenes(scene_id) ON DELETE SET NULL,
    evidence_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pattern_refs_pattern ON pattern_book_refs (pattern_id);
CREATE INDEX IF NOT EXISTS idx_pattern_refs_book ON pattern_book_refs (book_id);

CREATE TABLE IF NOT EXISTS genre_pattern_packs (
    genre_pack_id TEXT PRIMARY KEY CHECK (genre_pack_id ~ '^gpp_[A-Za-z0-9_-]+$'),
    genre TEXT[] NOT NULL,
    selection_rules JSONB NOT NULL DEFAULT '[]'::jsonb,
    version_tag TEXT NOT NULL DEFAULT 'v1',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_genre_packs_genre_gin ON genre_pattern_packs USING GIN (genre);

CREATE TABLE IF NOT EXISTS genre_pattern_pack_items (
    item_id TEXT PRIMARY KEY CHECK (item_id ~ '^gppi_[A-Za-z0-9_-]+$'),
    genre_pack_id TEXT NOT NULL REFERENCES genre_pattern_packs(genre_pack_id) ON DELETE CASCADE,
    pattern_id TEXT NOT NULL REFERENCES pattern_library(pattern_id) ON DELETE CASCADE,
    weight NUMERIC(5,4) NOT NULL DEFAULT 1.0 CHECK (weight >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_gpp_items_unique ON genre_pattern_pack_items (genre_pack_id, pattern_id);

CREATE TABLE IF NOT EXISTS extraction_jobs (
    job_id TEXT PRIMARY KEY CHECK (job_id ~ '^job_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    modes TEXT[] NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'running', 'success', 'failed', 'canceled')),
    progress_percent NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    error_message TEXT,
    created_by TEXT NOT NULL DEFAULT 'system',
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jobs_book ON extraction_jobs (book_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON extraction_jobs (status);

CREATE TABLE IF NOT EXISTS qa_reviews (
    review_id TEXT PRIMARY KEY CHECK (review_id ~ '^qarev_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    job_id TEXT REFERENCES extraction_jobs(job_id) ON DELETE SET NULL,
    target_type TEXT NOT NULL CHECK (target_type IN ('chapter', 'scene', 'character', 'world_rule', 'foreshadow', 'pattern')),
    target_id TEXT NOT NULL,
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
    issue_detail TEXT NOT NULL,
    fix_suggestion TEXT,
    decision TEXT NOT NULL DEFAULT 'open' CHECK (decision IN ('open', 'accepted', 'rejected', 'fixed')),
    reviewer TEXT NOT NULL DEFAULT 'auto',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_qa_reviews_book ON qa_reviews (book_id);
CREATE INDEX IF NOT EXISTS idx_qa_reviews_target ON qa_reviews (target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_qa_reviews_decision ON qa_reviews (decision);

-- Export snapshot for BookModelPack payloads
CREATE TABLE IF NOT EXISTS book_model_pack_exports (
    export_id TEXT PRIMARY KEY CHECK (export_id ~ '^exp_[A-Za-z0-9_-]+$'),
    book_id TEXT NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    schema_version TEXT NOT NULL DEFAULT 'v1',
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exports_book ON book_model_pack_exports (book_id);

COMMIT;

