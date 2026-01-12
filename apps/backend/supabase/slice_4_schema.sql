-- Slice 4: Fantasy Leagues Schema
-- Run this SQL in Supabase SQL Editor

-- Create leagues table
CREATE TABLE IF NOT EXISTS leagues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invite_code VARCHAR(20) UNIQUE NOT NULL,
    max_members INTEGER DEFAULT 10,
    is_public BOOLEAN DEFAULT false,
    draft_status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed
    draft_date TIMESTAMP WITH TIME ZONE,
    scoring_system JSONB DEFAULT '{"kill": 0.3, "death": -0.3, "assist": 0.15, "last_hit": 0.003, "gpm": 0.002, "xpm": 0.002}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create league_members table
CREATE TABLE IF NOT EXISTS league_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    league_id UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member', -- owner, admin, member
    team_name VARCHAR(100),
    total_points DECIMAL(10, 2) DEFAULT 0,
    rank INTEGER,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(league_id, user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_leagues_tournament ON leagues(tournament_id);
CREATE INDEX IF NOT EXISTS idx_leagues_owner ON leagues(owner_id);
CREATE INDEX IF NOT EXISTS idx_leagues_invite_code ON leagues(invite_code);
CREATE INDEX IF NOT EXISTS idx_leagues_public ON leagues(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_league_members_league ON league_members(league_id);
CREATE INDEX IF NOT EXISTS idx_league_members_user ON league_members(user_id);

-- Enable Row Level Security
ALTER TABLE leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE league_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies for leagues
-- Anyone can view public leagues
CREATE POLICY "Public leagues are viewable by everyone" ON leagues
    FOR SELECT USING (is_public = true);

-- Members can view their leagues
CREATE POLICY "League members can view their leagues" ON leagues
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM league_members
            WHERE league_members.league_id = leagues.id
            AND league_members.user_id = auth.uid()
        )
    );

-- Authenticated users can create leagues
CREATE POLICY "Authenticated users can create leagues" ON leagues
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Owners can update their leagues
CREATE POLICY "Owners can update their leagues" ON leagues
    FOR UPDATE USING (auth.uid() = owner_id);

-- Owners can delete their leagues
CREATE POLICY "Owners can delete their leagues" ON leagues
    FOR DELETE USING (auth.uid() = owner_id);

-- RLS Policies for league_members
-- Members can view members of their leagues
CREATE POLICY "Members can view league members" ON league_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM league_members lm
            WHERE lm.league_id = league_members.league_id
            AND lm.user_id = auth.uid()
        )
    );

-- Users can join leagues (insert themselves)
CREATE POLICY "Users can join leagues" ON league_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own membership
CREATE POLICY "Users can update their membership" ON league_members
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can leave leagues (delete their membership)
CREATE POLICY "Users can leave leagues" ON league_members
    FOR DELETE USING (auth.uid() = user_id);

-- League owners can manage members
CREATE POLICY "League owners can manage members" ON league_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM leagues
            WHERE leagues.id = league_members.league_id
            AND leagues.owner_id = auth.uid()
        )
    );

-- Function to generate invite code
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate invite code
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_invite_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_invite_code ON leagues;
CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON leagues
    FOR EACH ROW
    EXECUTE FUNCTION set_invite_code();

-- Trigger to add owner as member when league is created
CREATE OR REPLACE FUNCTION add_owner_as_member()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO league_members (league_id, user_id, role, team_name)
    VALUES (NEW.id, NEW.owner_id, 'owner', 'My Team');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_add_owner_as_member ON leagues;
CREATE TRIGGER trigger_add_owner_as_member
    AFTER INSERT ON leagues
    FOR EACH ROW
    EXECUTE FUNCTION add_owner_as_member();
