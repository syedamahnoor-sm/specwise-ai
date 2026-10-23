CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================================
-- 1. Projects
-- ==========================================

CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    initial_idea TEXT NOT NULL,
    description TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 2. Conversations
-- ==========================================

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    role VARCHAR(30) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 3. Requirements
-- ==========================================

CREATE TABLE IF NOT EXISTS requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    requirement_type VARCHAR(30),
    priority VARCHAR(30),
    status VARCHAR(30),
    source VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 4. Clarification Questions
-- ==========================================

CREATE TABLE IF NOT EXISTS clarification_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    requirement_id UUID REFERENCES requirements(id),
    question TEXT NOT NULL,
    answer TEXT,
    category VARCHAR(30),
    priority VARCHAR(10),
    status VARCHAR(30),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    answered_at TIMESTAMPTZ
);

-- ==========================================
-- 5. Specification Versions
-- ==========================================

CREATE TABLE IF NOT EXISTS specification_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    version_number INTEGER NOT NULL,
    content JSONB NOT NULL,
    status VARCHAR(30),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (project_id, version_number),
    UNIQUE (id, project_id)
);

-- ==========================================
-- 6. Approvals
-- ==========================================

CREATE TABLE IF NOT EXISTS approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    specification_id UUID NOT NULL,
    decision VARCHAR(30) NOT NULL,
    feedback TEXT,
    decided_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (specification_id, project_id)
        REFERENCES specification_versions(id, project_id)
);

-- ==========================================
-- Migration for existing databases
-- ==========================================

ALTER TABLE clarification_questions
    ADD COLUMN IF NOT EXISTS category VARCHAR(30);

ALTER TABLE clarification_questions
    ADD COLUMN IF NOT EXISTS priority VARCHAR(10);