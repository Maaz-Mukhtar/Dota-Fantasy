-- Complete RLS fix for league_members - Run this in Supabase SQL Editor
-- This drops ALL existing SELECT policies and creates clean ones

-- First, drop ALL existing policies on league_members to start fresh
DROP POLICY IF EXISTS "Members can view league members" ON league_members;
DROP POLICY IF EXISTS "Users can view own membership" ON league_members;
DROP POLICY IF EXISTS "League owners can view members" ON league_members;
DROP POLICY IF EXISTS "Users can join leagues" ON league_members;
DROP POLICY IF EXISTS "Users can update their membership" ON league_members;
DROP POLICY IF EXISTS "Users can leave leagues" ON league_members;
DROP POLICY IF EXISTS "League owners can manage members" ON league_members;

-- Create the security definer function first (bypasses RLS)
CREATE OR REPLACE FUNCTION get_user_league_ids(user_uuid UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT league_id FROM league_members WHERE user_id = user_uuid;
$$;

-- Now create clean policies

-- SELECT: Users can view members of leagues they belong to
CREATE POLICY "View league members" ON league_members
    FOR SELECT USING (
        league_id IN (SELECT get_user_league_ids(auth.uid()))
    );

-- INSERT: Users can join leagues (add themselves)
CREATE POLICY "Join leagues" ON league_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can update their own membership
CREATE POLICY "Update own membership" ON league_members
    FOR UPDATE USING (auth.uid() = user_id);

-- DELETE: Users can leave leagues OR league owners can remove members
CREATE POLICY "Leave or remove from leagues" ON league_members
    FOR DELETE USING (
        auth.uid() = user_id
        OR
        EXISTS (
            SELECT 1 FROM leagues
            WHERE leagues.id = league_members.league_id
            AND leagues.owner_id = auth.uid()
        )
    );
