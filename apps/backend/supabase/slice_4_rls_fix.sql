-- Fix RLS infinite recursion for league_members
-- Run this in Supabase SQL Editor

-- Drop the problematic policy
DROP POLICY IF EXISTS "Members can view league members" ON league_members;

-- Create a simpler policy that doesn't self-reference
-- Users can view their own membership records
CREATE POLICY "Users can view own membership" ON league_members
    FOR SELECT USING (auth.uid() = user_id);

-- League owners can view all members in their leagues (via leagues table, not self-reference)
CREATE POLICY "League owners can view members" ON league_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM leagues
            WHERE leagues.id = league_members.league_id
            AND leagues.owner_id = auth.uid()
        )
    );

-- Members can view other members in the same league
-- We use a security definer function to avoid recursion
CREATE OR REPLACE FUNCTION get_user_league_ids(user_uuid UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT league_id FROM league_members WHERE user_id = user_uuid;
$$;

-- Now create policy using the function
CREATE POLICY "Members can view league members" ON league_members
    FOR SELECT USING (
        league_id IN (SELECT get_user_league_ids(auth.uid()))
    );
