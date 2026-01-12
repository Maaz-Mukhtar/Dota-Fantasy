-- Slice 5: Player Database Schema
-- Run this in Supabase SQL Editor

-- Players table
CREATE TABLE IF NOT EXISTS public.players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nickname VARCHAR(100) NOT NULL,
    real_name VARCHAR(255),
    role VARCHAR(20),  -- 'carry', 'mid', 'offlane', 'support4', 'support5'
    team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    country VARCHAR(100),
    avatar_url VARCHAR(500),
    stratz_id BIGINT UNIQUE,
    steam_id BIGINT UNIQUE,
    -- Cached stats (updated periodically)
    avg_kills DECIMAL(5, 2) DEFAULT 0,
    avg_deaths DECIMAL(5, 2) DEFAULT 0,
    avg_assists DECIMAL(5, 2) DEFAULT 0,
    avg_gpm DECIMAL(7, 2) DEFAULT 0,
    avg_xpm DECIMAL(7, 2) DEFAULT 0,
    avg_last_hits DECIMAL(7, 2) DEFAULT 0,
    avg_fantasy_points DECIMAL(7, 2) DEFAULT 0,
    total_matches INTEGER DEFAULT 0,
    win_rate DECIMAL(5, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournament Players (players participating in a tournament)
CREATE TABLE IF NOT EXISTS public.tournament_players (
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
    player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    fantasy_value DECIMAL(10, 2) DEFAULT 100,  -- For salary cap leagues
    tournament_stats JSONB DEFAULT '{}',  -- Tournament-specific cached stats
    PRIMARY KEY (tournament_id, player_id)
);

-- Player Match Stats (individual game performance)
CREATE TABLE IF NOT EXISTS public.player_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    game_number INTEGER DEFAULT 1,  -- Game 1, 2, 3, etc. within a match series
    -- Core stats
    kills INTEGER DEFAULT 0,
    deaths INTEGER DEFAULT 0,
    assists INTEGER DEFAULT 0,
    last_hits INTEGER DEFAULT 0,
    denies INTEGER DEFAULT 0,
    gpm INTEGER DEFAULT 0,
    xpm INTEGER DEFAULT 0,
    -- Damage stats
    hero_damage INTEGER DEFAULT 0,
    tower_damage INTEGER DEFAULT 0,
    hero_healing INTEGER DEFAULT 0,
    -- Support stats
    stuns DECIMAL(8, 2) DEFAULT 0,
    obs_placed INTEGER DEFAULT 0,
    camps_stacked INTEGER DEFAULT 0,
    -- Other
    first_blood BOOLEAN DEFAULT false,
    hero_id INTEGER,
    is_winner BOOLEAN DEFAULT false,
    is_radiant BOOLEAN,
    -- Calculated fantasy points
    fantasy_points DECIMAL(10, 2) DEFAULT 0,
    -- Raw data from API
    raw_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(player_id, match_id, game_number)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_players_team ON public.players(team_id);
CREATE INDEX IF NOT EXISTS idx_players_role ON public.players(role);
CREATE INDEX IF NOT EXISTS idx_players_stratz ON public.players(stratz_id);
CREATE INDEX IF NOT EXISTS idx_players_nickname ON public.players(nickname);

CREATE INDEX IF NOT EXISTS idx_tournament_players_tournament ON public.tournament_players(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_players_player ON public.tournament_players(player_id);
CREATE INDEX IF NOT EXISTS idx_tournament_players_team ON public.tournament_players(team_id);

CREATE INDEX IF NOT EXISTS idx_player_stats_player ON public.player_stats(player_id);
CREATE INDEX IF NOT EXISTS idx_player_stats_match ON public.player_stats(match_id);

-- RLS Policies
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_stats ENABLE ROW LEVEL SECURITY;

-- Players are viewable by everyone
CREATE POLICY "Players are viewable by everyone"
    ON public.players FOR SELECT
    USING (true);

-- Tournament players are viewable by everyone
CREATE POLICY "Tournament players are viewable by everyone"
    ON public.tournament_players FOR SELECT
    USING (true);

-- Player stats are viewable by everyone
CREATE POLICY "Player stats are viewable by everyone"
    ON public.player_stats FOR SELECT
    USING (true);

-- Insert some sample players for testing (associated with existing teams)
-- You can run this after teams exist in the database

-- Function to update player's updated_at timestamp
CREATE OR REPLACE FUNCTION update_player_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_players_timestamp
    BEFORE UPDATE ON public.players
    FOR EACH ROW
    EXECUTE FUNCTION update_player_timestamp();

-- Sample Players for Testing
-- Insert players with various roles and stats
INSERT INTO public.players (id, nickname, real_name, role, country, avg_kills, avg_deaths, avg_assists, avg_gpm, avg_xpm, avg_last_hits, avg_fantasy_points, total_matches, win_rate) VALUES
    ('a1111111-1111-1111-1111-111111111111', 'Yatoro', 'Illya Mulyarchuk', 'carry', 'Ukraine', 7.2, 3.1, 8.5, 625, 580, 320, 18.5, 450, 62.5),
    ('a2222222-2222-2222-2222-222222222222', 'Collapse', 'Magomed Khalilov', 'offlane', 'Russia', 5.8, 4.2, 12.3, 480, 520, 180, 16.2, 420, 61.8),
    ('a3333333-3333-3333-3333-333333333333', 'Mira', 'Miroslaw Kolpakov', 'mid', 'Ukraine', 8.1, 3.5, 9.2, 590, 620, 290, 19.1, 380, 60.2),
    ('a4444444-4444-4444-4444-444444444444', 'Miposhka', 'Yaroslav Naidenov', 'support5', 'Russia', 2.1, 5.8, 15.2, 280, 320, 45, 12.8, 480, 63.1),
    ('a5555555-5555-5555-5555-555555555555', 'Torontotokyo', 'Alexander Khertek', 'support4', 'Russia', 3.2, 5.2, 14.8, 320, 380, 65, 13.5, 410, 59.8),
    ('b1111111-1111-1111-1111-111111111111', 'Ame', 'Wang Chunyu', 'carry', 'China', 7.8, 2.9, 7.8, 650, 590, 340, 19.2, 520, 64.2),
    ('b2222222-2222-2222-2222-222222222222', 'NothingToSay', 'Cheng Jin Xiang', 'mid', 'Malaysia', 7.5, 3.2, 10.1, 580, 610, 280, 18.4, 490, 62.8),
    ('b3333333-3333-3333-3333-333333333333', 'Faith_bian', 'Zhang Ruida', 'offlane', 'China', 4.9, 4.5, 13.2, 450, 490, 165, 15.1, 510, 61.5),
    ('b4444444-4444-4444-4444-444444444444', 'XinQ', 'Zhao Zixing', 'support4', 'China', 3.5, 5.1, 15.5, 330, 390, 72, 14.2, 480, 63.5),
    ('b5555555-5555-5555-5555-555555555555', 'y`', 'Zhang Yiping', 'support5', 'China', 2.3, 5.5, 14.8, 290, 330, 48, 12.5, 500, 62.1),
    ('c1111111-1111-1111-1111-111111111111', 'Arteezy', 'Artour Babaev', 'carry', 'Canada', 6.9, 3.4, 8.2, 610, 560, 310, 17.8, 580, 58.5),
    ('c2222222-2222-2222-2222-222222222222', 'Quinn', 'Quinn Callahan', 'mid', 'USA', 7.2, 3.8, 9.5, 560, 590, 270, 17.5, 450, 57.2),
    ('c3333333-3333-3333-3333-333333333333', 'SabeRLight-', 'Jonáš Volek', 'offlane', 'Czech Republic', 5.1, 4.8, 12.8, 440, 480, 155, 14.8, 420, 56.8),
    ('c4444444-4444-4444-4444-444444444444', 'Cr1t-', 'Andreas Nielsen', 'support4', 'Denmark', 3.8, 4.9, 16.2, 340, 400, 78, 14.8, 560, 59.2),
    ('c5555555-5555-5555-5555-555555555555', 'Fly', 'Tal Aizik', 'support5', 'Israel', 2.5, 5.2, 15.5, 300, 350, 52, 13.2, 620, 58.8),
    ('d1111111-1111-1111-1111-111111111111', 'Ana', 'Anathan Pham', 'carry', 'Australia', 8.5, 2.8, 7.5, 680, 610, 355, 20.5, 280, 68.5),
    ('d2222222-2222-2222-2222-222222222222', 'Topson', 'Topias Taavitsainen', 'mid', 'Finland', 8.8, 4.1, 10.2, 550, 600, 260, 19.8, 320, 65.2),
    ('d3333333-3333-3333-3333-333333333333', 'Ceb', 'Sébastien Debs', 'offlane', 'France', 4.5, 4.2, 14.5, 420, 470, 145, 15.5, 380, 64.8),
    ('d4444444-4444-4444-4444-444444444444', 'JerAx', 'Jesse Vainikka', 'support4', 'Finland', 4.2, 4.8, 17.2, 350, 410, 85, 15.8, 340, 66.2),
    ('d5555555-5555-5555-5555-555555555555', 'N0tail', 'Johan Sundstein', 'support5', 'Denmark', 2.8, 5.0, 16.8, 310, 360, 58, 14.2, 520, 63.5)
ON CONFLICT (id) DO NOTHING;

-- Associate players with tournaments (use actual tournament IDs from your database)
-- First, get tournament IDs:
-- SELECT id, name FROM tournaments;

-- Example: Add players to The International 2025 (replace with actual tournament ID)
-- INSERT INTO public.tournament_players (tournament_id, player_id, fantasy_value)
-- SELECT
--     '0530f7be-62ce-4512-8c6f-60437f95104b',  -- TI 2025 ID
--     id,
--     CASE
--         WHEN avg_fantasy_points > 18 THEN 150
--         WHEN avg_fantasy_points > 15 THEN 120
--         ELSE 100
--     END
-- FROM public.players;
