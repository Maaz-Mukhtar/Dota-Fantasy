-- Slice 3: Teams and Matches Schema
-- Run this SQL in Supabase SQL Editor

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    tag VARCHAR(50),
    logo_url TEXT,
    region VARCHAR(50),
    liquipedia_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create tournament_teams junction table
CREATE TABLE IF NOT EXISTS tournament_teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    seed INTEGER,
    group_name VARCHAR(50),
    placement INTEGER,
    prize_won DECIMAL(15, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, team_id)
);

-- Create matches table
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    team1_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    team2_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    winner_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    stage VARCHAR(100),
    round VARCHAR(100),
    match_number INTEGER,
    best_of INTEGER DEFAULT 3,
    status VARCHAR(50) DEFAULT 'scheduled',
    stream_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tournament_teams_tournament ON tournament_teams(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_teams_team ON tournament_teams(team_id);
CREATE INDEX IF NOT EXISTS idx_matches_tournament ON matches(tournament_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_scheduled ON matches(scheduled_at);

-- Enable Row Level Security
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- RLS Policies for teams (public read)
CREATE POLICY "Teams are viewable by everyone" ON teams
    FOR SELECT USING (true);

-- RLS Policies for tournament_teams (public read)
CREATE POLICY "Tournament teams are viewable by everyone" ON tournament_teams
    FOR SELECT USING (true);

-- RLS Policies for matches (public read)
CREATE POLICY "Matches are viewable by everyone" ON matches
    FOR SELECT USING (true);

-- Insert sample teams
INSERT INTO teams (id, name, tag, region) VALUES
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Team Spirit', 'TS', 'CIS'),
    ('b2c3d4e5-f6a7-8901-bcde-f23456789012', 'Team Liquid', 'Liquid', 'Europe'),
    ('c3d4e5f6-a7b8-9012-cdef-345678901234', 'Gaimin Gladiators', 'GG', 'Europe'),
    ('d4e5f6a7-b8c9-0123-def0-456789012345', 'BetBoom Team', 'BB', 'CIS'),
    ('e5f6a7b8-c9d0-1234-ef01-567890123456', 'Tundra Esports', 'Tundra', 'Europe'),
    ('f6a7b8c9-d0e1-2345-f012-678901234567', 'Cloud9', 'C9', 'North America'),
    ('a7b8c9d0-e1f2-3456-0123-789012345678', 'PSG.LGD', 'LGD', 'China'),
    ('b8c9d0e1-f2a3-4567-1234-890123456789', 'Azure Ray', 'AR', 'China')
ON CONFLICT (id) DO NOTHING;

-- Link teams to TI 2024 (ongoing tournament)
INSERT INTO tournament_teams (tournament_id, team_id, seed, group_name)
SELECT
    '9a9500f1-d9ae-4eb6-b827-c9a92e41591e',
    t.id,
    ROW_NUMBER() OVER (ORDER BY t.name),
    CASE WHEN ROW_NUMBER() OVER (ORDER BY t.name) <= 4 THEN 'Group A' ELSE 'Group B' END
FROM teams t
ON CONFLICT (tournament_id, team_id) DO NOTHING;

-- Insert sample matches for TI 2024
INSERT INTO matches (tournament_id, team1_id, team2_id, stage, round, best_of, status, scheduled_at, team1_score, team2_score) VALUES
    -- Group A matches
    ('9a9500f1-d9ae-4eb6-b827-c9a92e41591e', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'Group Stage', 'Round 1', 2, 'completed', NOW() - INTERVAL '2 days', 2, 1),
    ('9a9500f1-d9ae-4eb6-b827-c9a92e41591e', 'c3d4e5f6-a7b8-9012-cdef-345678901234', 'd4e5f6a7-b8c9-0123-def0-456789012345', 'Group Stage', 'Round 1', 2, 'completed', NOW() - INTERVAL '2 days', 1, 2),
    -- Live match
    ('9a9500f1-d9ae-4eb6-b827-c9a92e41591e', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'c3d4e5f6-a7b8-9012-cdef-345678901234', 'Group Stage', 'Round 2', 2, 'live', NOW(), 1, 1),
    -- Upcoming matches
    ('9a9500f1-d9ae-4eb6-b827-c9a92e41591e', 'b2c3d4e5-f6a7-8901-bcde-f23456789012', 'd4e5f6a7-b8c9-0123-def0-456789012345', 'Group Stage', 'Round 2', 2, 'scheduled', NOW() + INTERVAL '2 hours', 0, 0),
    ('9a9500f1-d9ae-4eb6-b827-c9a92e41591e', 'e5f6a7b8-c9d0-1234-ef01-567890123456', 'f6a7b8c9-d0e1-2345-f012-678901234567', 'Group Stage', 'Round 1', 2, 'scheduled', NOW() + INTERVAL '4 hours', 0, 0),
    ('9a9500f1-d9ae-4eb6-b827-c9a92e41591e', 'a7b8c9d0-e1f2-3456-0123-789012345678', 'b8c9d0e1-f2a3-4567-1234-890123456789', 'Group Stage', 'Round 1', 2, 'scheduled', NOW() + INTERVAL '6 hours', 0, 0)
ON CONFLICT DO NOTHING;

-- Update winner_id for completed matches
UPDATE matches
SET winner_id = team1_id
WHERE status = 'completed' AND team1_score > team2_score AND winner_id IS NULL;

UPDATE matches
SET winner_id = team2_id
WHERE status = 'completed' AND team2_score > team1_score AND winner_id IS NULL;
