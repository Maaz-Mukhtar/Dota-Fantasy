# Plan: Test Tournament Detail Screen with TI 2025 Data

## Objective
Populate the database with realistic TI 2025 data and test the redesigned tournament detail screen.

---

## Current State
- **TI 2025 Tournament ID**: `0530f7be-62ce-4512-8c6f-60437f95104b` (exists in database)
- **API Endpoints Available**:
  - `GET /tournaments/ti/2025/external` - Liquipedia + STRATZ combined data
  - `GET /liquipedia/ti-full/2025` - Full rosters from Liquipedia
  - `GET /liquipedia/ti-stages/2025` - Match stages mapping
- **Database Tables**: tournaments, teams, tournament_teams, players, tournament_players, matches

---

## Implementation Steps

### Step 1: Verify TI 2025 Tournament Record
- Check if TI 2025 exists in database with correct data
- Update tournament record if needed (status, dates, prize pool)

### Step 2: Fetch Team Data from Liquipedia
- Call `/liquipedia/ti-full/2025` to get all participating teams with rosters
- Expected: 16-20 teams with full 5-player rosters

### Step 3: Populate Teams in Database
- Insert/update teams in `teams` table
- Create `tournament_teams` records with:
  - Group assignments (Group A, Group B for Swiss rounds)
  - Seeds (if available)
  - Placements (after matches)

### Step 4: Populate Players in Database
- Insert/update players in `players` table from roster data
- Create `tournament_players` records linking players to TI 2025
- Include: role, team_id, country

### Step 5: Fetch Match Data from STRATZ
- Get STRATZ league ID from Liquipedia data
- Call `/stratz/league/{leagueId}/matches` for all matches
- Call `/liquipedia/ti-stages/2025` for stage mapping

### Step 6: Populate Matches in Database
- Insert matches into `matches` table with:
  - Stage: "Group Stage" or "Playoffs"
  - Round: "Round 1", "Upper Bracket Round 1", "Grand Final", etc.
  - Teams, scores, winner
  - Best of format (Bo2 for groups, Bo3/Bo5 for playoffs)

### Step 7: Test Tournament Detail Screen
- Navigate to TI 2025 in the app
- Verify:
  - Teams grid shows all 16-20 teams
  - Team tap shows roster in bottom sheet
  - Group Stage tab shows Swiss standings
  - Playoffs tab shows bracket visualization
  - Overflow menu items work (Info, Players, Schedule)

---

## API Calls Sequence

```
1. GET /tournaments (find TI 2025 ID)
2. GET /liquipedia/ti-full/2025 (teams + rosters)
3. GET /tournaments/ti/2025/external?includeMatches=true (combined data)
4. GET /liquipedia/ti-stages/2025 (stage mapping)
```

---

## Data Structure Expected

### Teams (16-20 teams)
- Team Spirit, Team Liquid, Gaimin Gladiators, Tundra Esports
- BetBoom Team, Cloud9, PSG.LGD, Azure Ray, etc.

### Group Stage Format (Swiss)
- Round 1-5 matches
- Elimination Round (if needed)
- Teams advance based on W-L record

### Playoffs Format
- Upper Bracket (8 teams)
- Lower Bracket (eliminations)
- Grand Final (Bo5)

---

## Implementation Options

### Option A: Backend Script (Recommended)
Create a backend seed script to:
1. Fetch data from external APIs
2. Transform and insert into database
3. Run once to populate all TI 2025 data

### Option B: Manual API Calls
1. Use Postman/curl to call external APIs
2. Manually insert data via Supabase dashboard
3. More control but time-consuming

### Option C: Mobile App Integration
1. Add a "sync" feature to fetch and cache external data
2. Store in local database or sync to backend
3. Best for real-time updates during live tournament

---

## Files to Create/Modify

### Backend
- `backend/src/scripts/seed-ti2025.ts` - Seed script for TI 2025 data

### Mobile (if needed)
- Update tournament repository to handle external data
- Add sync functionality for live tournaments

---

## Success Criteria
1. TI 2025 appears in tournament list with correct info
2. Clicking TI 2025 shows teams grid with all participating teams
3. Tapping a team shows full roster (5 players + coach)
4. Group Stage tab shows Swiss standings with W-L records
5. Playoffs tab shows bracket with match results
6. Players screen shows all tournament players with filters
7. Schedule screen shows all matches organized by status
