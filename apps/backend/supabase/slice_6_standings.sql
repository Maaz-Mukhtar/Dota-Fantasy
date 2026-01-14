-- Add standings columns to tournament_teams for group stage W-L-D tracking
-- Run this migration after slice_5_schema.sql

-- Add wins, losses, draws columns
ALTER TABLE tournament_teams
ADD COLUMN IF NOT EXISTS wins INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS losses INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS draws INTEGER DEFAULT 0;

-- Add game_wins and game_losses for tiebreaker scenarios
ALTER TABLE tournament_teams
ADD COLUMN IF NOT EXISTS game_wins INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS game_losses INTEGER DEFAULT 0;
