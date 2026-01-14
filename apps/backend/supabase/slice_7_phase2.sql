-- Slice 7: Add STRATZ match ID for Phase 2 tracking
-- Run this SQL in Supabase SQL Editor

-- Add stratz_match_id column to matches table
-- This allows us to track individual game IDs from STRATZ
ALTER TABLE matches ADD COLUMN IF NOT EXISTS stratz_match_id BIGINT;

-- Create index for faster lookups by STRATZ match ID
CREATE INDEX IF NOT EXISTS idx_matches_stratz_match_id ON matches(stratz_match_id);
