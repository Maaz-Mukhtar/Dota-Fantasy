/**
 * Seed script for TI 2025 data
 *
 * This script fetches TI 2025 data from Liquipedia via the backend API
 * and populates the database with teams, players, and matches.
 *
 * Usage:
 *   1. Make sure the backend is running: npm run start:dev
 *   2. Run this script: npx ts-node scripts/seed-ti2025.ts
 */

import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

// Configuration
const TI_2025_ID = '0530f7be-62ce-4512-8c6f-60437f95104b';
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Types from Liquipedia
interface ParticipantPlayer {
  nickname: string;
  position?: number;
  country?: string;
  isSubstitute?: boolean;
}

interface TournamentParticipant {
  teamName: string;
  players: ParticipantPlayer[];
  coach?: string;
  qualifier?: string;
  placement?: string;
  notes?: string;
  logoUrl?: string;
  logoDarkUrl?: string;
}

interface TournamentInfo {
  name: string;
  shortName?: string;
  tier?: string;
  prizePool?: string;
  prizePoolUsd?: number;
  startDate?: string;
  endDate?: string;
  leagueId?: string;
  liquipediaUrl: string;
  directInvites?: TournamentParticipant[];
  qualifiedTeams?: TournamentParticipant[];
}

// Helper to generate deterministic UUIDs based on name
function generateTeamId(teamName: string): string {
  // Create a simple hash-based UUID
  const hash = teamName.split('').reduce((acc, char, idx) => {
    return acc + char.charCodeAt(0) * (idx + 1);
  }, 0);
  const hex = hash.toString(16).padStart(8, '0');
  return `${hex.slice(0, 8)}-${hex.slice(0, 4)}-4${hex.slice(1, 4)}-8${hex.slice(1, 4)}-${hex.padStart(12, '0').slice(0, 12)}`;
}

function generatePlayerId(nickname: string, teamName: string): string {
  // Combine team name and nickname to ensure uniqueness
  const combined = `${teamName}_${nickname}`.toLowerCase();
  let hash = 0;
  for (let i = 0; i < combined.length; i++) {
    const char = combined.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  // Make hash positive and create unique hex
  const absHash = Math.abs(hash);
  const hex1 = absHash.toString(16).padStart(8, '0');
  const hex2 = (absHash * 31).toString(16).padStart(8, '0');
  const hex3 = (absHash * 37).toString(16).padStart(12, '0');
  return `${hex1.slice(0, 8)}-${hex2.slice(0, 4)}-4${hex2.slice(4, 7)}-8${hex1.slice(4, 7)}-${hex3.slice(0, 12)}`;
}

function positionToRole(position?: number): string | undefined {
  if (!position) return undefined;
  switch (position) {
    case 1: return 'carry';
    case 2: return 'mid';
    case 3: return 'offlane';
    case 4: return 'support4';
    case 5: return 'support5';
    default: return undefined;
  }
}

function inferRegion(qualifier?: string, notes?: string): string | undefined {
  const text = `${qualifier || ''} ${notes || ''}`.toLowerCase();
  if (text.includes('western europe') || text.includes('weu')) return 'Western Europe';
  if (text.includes('eastern europe') || text.includes('eeu') || text.includes('cis')) return 'Eastern Europe';
  if (text.includes('china') || text.includes('cn')) return 'China';
  if (text.includes('sea') || text.includes('southeast asia')) return 'Southeast Asia';
  if (text.includes('north america') || text.includes('na')) return 'North America';
  if (text.includes('south america') || text.includes('sa')) return 'South America';
  if (text.includes('invited')) return 'Invited';
  return undefined;
}

async function fetchTournamentData(): Promise<TournamentInfo | null> {
  console.log('Fetching TI 2025 data from backend API...');

  try {
    const response = await fetch(`${BACKEND_URL}/api/v1/liquipedia/ti-full-logos/2025`);

    if (!response.ok) {
      throw new Error(`API responded with status ${response.status}`);
    }

    const json = await response.json() as { success: boolean; data: TournamentInfo };

    if (!json.success || !json.data) {
      throw new Error('API returned unsuccessful response');
    }

    const data = json.data;
    console.log(`Fetched tournament: ${data.name}`);
    console.log(`  Direct Invites: ${data.directInvites?.length || 0}`);
    console.log(`  Qualified Teams: ${data.qualifiedTeams?.length || 0}`);

    return data;
  } catch (error) {
    console.error('Failed to fetch tournament data:', error);
    return null;
  }
}

async function updateTournament(tournamentData: TournamentInfo) {
  console.log('\nUpdating tournament record...');

  const { error } = await supabase
    .from('tournaments')
    .update({
      name: tournamentData.name,
      prize_pool: tournamentData.prizePoolUsd || 0,
      start_date: tournamentData.startDate || null,
      end_date: tournamentData.endDate || null,
      liquipedia_url: tournamentData.liquipediaUrl,
      updated_at: new Date().toISOString(),
    })
    .eq('id', TI_2025_ID);

  if (error) {
    console.error('Error updating tournament:', error);
    return false;
  }

  console.log('Tournament updated successfully!');
  return true;
}

async function upsertTeams(participants: TournamentParticipant[]) {
  console.log(`\nUpserting ${participants.length} teams...`);

  const teamsData = participants.map(p => ({
    id: generateTeamId(p.teamName),
    name: p.teamName,
    tag: p.teamName.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 4),
    logo_url: p.logoUrl || null,
    region: inferRegion(p.qualifier, p.notes),
    liquipedia_url: `https://liquipedia.net/dota2/${p.teamName.replace(/ /g, '_')}`,
    updated_at: new Date().toISOString(),
  }));

  const { error } = await supabase
    .from('teams')
    .upsert(teamsData, { onConflict: 'id' });

  if (error) {
    console.error('Error upserting teams:', error);
    return [];
  }

  console.log(`Successfully upserted ${teamsData.length} teams`);
  return teamsData;
}

async function linkTeamsToTournament(
  participants: TournamentParticipant[],
  teamsData: { id: string; name: string }[]
) {
  console.log('\nLinking teams to tournament...');

  const tournamentTeamsData = participants.map((p, idx) => {
    const team = teamsData.find(t => t.name === p.teamName);
    return {
      tournament_id: TI_2025_ID,
      team_id: team?.id || generateTeamId(p.teamName),
      seed: idx + 1,
      group_name: idx < 10 ? 'Group A' : 'Group B', // TI typically has Swiss groups
      placement: p.placement ? parseInt(p.placement.replace(/[^0-9]/g, '')) || null : null,
    };
  });

  // Delete existing links first
  await supabase
    .from('tournament_teams')
    .delete()
    .eq('tournament_id', TI_2025_ID);

  const { error } = await supabase
    .from('tournament_teams')
    .insert(tournamentTeamsData);

  if (error) {
    console.error('Error linking teams to tournament:', error);
    return false;
  }

  console.log(`Linked ${tournamentTeamsData.length} teams to TI 2025`);
  return true;
}

async function upsertPlayers(
  participants: TournamentParticipant[],
  teamsData: { id: string; name: string }[]
) {
  console.log('\nUpserting players...');

  const playersData: Array<{
    id: string;
    nickname: string;
    role: string | undefined;
    team_id: string;
    country: string | undefined;
    updated_at: string;
  }> = [];

  for (const participant of participants) {
    const team = teamsData.find(t => t.name === participant.teamName);
    const teamId = team?.id || generateTeamId(participant.teamName);

    for (const player of participant.players) {
      if (player.isSubstitute) continue; // Skip subs for now

      playersData.push({
        id: generatePlayerId(player.nickname, participant.teamName),
        nickname: player.nickname,
        role: positionToRole(player.position),
        team_id: teamId,
        country: player.country,
        updated_at: new Date().toISOString(),
      });
    }
  }

  if (playersData.length === 0) {
    console.log('No players to insert');
    return [];
  }

  const { error } = await supabase
    .from('players')
    .upsert(playersData, { onConflict: 'id' });

  if (error) {
    console.error('Error upserting players:', error);
    return [];
  }

  console.log(`Successfully upserted ${playersData.length} players`);
  return playersData;
}

async function linkPlayersToTournament(
  playersData: { id: string; team_id: string }[]
) {
  console.log('\nLinking players to tournament...');

  // Delete existing links first
  await supabase
    .from('tournament_players')
    .delete()
    .eq('tournament_id', TI_2025_ID);

  const tournamentPlayersData = playersData.map(player => ({
    tournament_id: TI_2025_ID,
    player_id: player.id,
    team_id: player.team_id,
    is_active: true,
    fantasy_value: 100,
  }));

  const { error } = await supabase
    .from('tournament_players')
    .insert(tournamentPlayersData);

  if (error) {
    console.error('Error linking players to tournament:', error);
    return false;
  }

  console.log(`Linked ${tournamentPlayersData.length} players to TI 2025`);
  return true;
}

async function createSampleMatches(teamsData: { id: string; name: string }[]) {
  console.log('\nCreating sample group stage matches...');

  if (teamsData.length < 4) {
    console.log('Not enough teams to create matches');
    return;
  }

  // Delete existing matches first
  await supabase
    .from('matches')
    .delete()
    .eq('tournament_id', TI_2025_ID);

  const now = new Date();
  const matchesData = [];

  // Create round-robin style group stage matches
  const groupATeams = teamsData.slice(0, Math.min(10, teamsData.length));

  // Round 1: First set of matches
  for (let i = 0; i < groupATeams.length - 1; i += 2) {
    matchesData.push({
      tournament_id: TI_2025_ID,
      team1_id: groupATeams[i].id,
      team2_id: groupATeams[i + 1].id,
      stage: 'Group Stage',
      round: 'Round 1',
      best_of: 2,
      status: 'scheduled',
      scheduled_at: new Date(now.getTime() + (i * 3600000)).toISOString(),
    });
  }

  // Round 2
  for (let i = 1; i < groupATeams.length - 1; i += 2) {
    if (i + 1 < groupATeams.length) {
      matchesData.push({
        tournament_id: TI_2025_ID,
        team1_id: groupATeams[i].id,
        team2_id: groupATeams[i + 1].id,
        stage: 'Group Stage',
        round: 'Round 2',
        best_of: 2,
        status: 'scheduled',
        scheduled_at: new Date(now.getTime() + ((i + 10) * 3600000)).toISOString(),
      });
    }
  }

  // Add playoff placeholder matches
  const playoffTeams = teamsData.slice(0, 8);
  for (let i = 0; i < playoffTeams.length - 1; i += 2) {
    matchesData.push({
      tournament_id: TI_2025_ID,
      team1_id: playoffTeams[i].id,
      team2_id: playoffTeams[i + 1].id,
      stage: 'Playoffs',
      round: 'Upper Bracket Round 1',
      best_of: 3,
      status: 'scheduled',
      scheduled_at: new Date(now.getTime() + (86400000 * 5) + (i * 7200000)).toISOString(),
    });
  }

  if (matchesData.length > 0) {
    const { error } = await supabase
      .from('matches')
      .insert(matchesData);

    if (error) {
      console.error('Error creating matches:', error);
      return;
    }

    console.log(`Created ${matchesData.length} sample matches`);
  }
}

async function printSummary() {
  console.log('\n========== SEEDING SUMMARY ==========\n');

  // Count teams
  const { count: teamsCount } = await supabase
    .from('tournament_teams')
    .select('*', { count: 'exact', head: true })
    .eq('tournament_id', TI_2025_ID);

  // Count players
  const { count: playersCount } = await supabase
    .from('tournament_players')
    .select('*', { count: 'exact', head: true })
    .eq('tournament_id', TI_2025_ID);

  // Count matches
  const { count: matchesCount } = await supabase
    .from('matches')
    .select('*', { count: 'exact', head: true })
    .eq('tournament_id', TI_2025_ID);

  console.log(`TI 2025 Tournament ID: ${TI_2025_ID}`);
  console.log(`Teams in tournament: ${teamsCount || 0}`);
  console.log(`Players in tournament: ${playersCount || 0}`);
  console.log(`Matches scheduled: ${matchesCount || 0}`);
  console.log('\n=====================================\n');
}

async function main() {
  console.log('===========================================');
  console.log('   TI 2025 Data Seeder');
  console.log('===========================================\n');

  // Step 1: Fetch tournament data from API
  const tournamentData = await fetchTournamentData();

  if (!tournamentData) {
    console.error('\nFailed to fetch tournament data. Make sure the backend is running.');
    console.log('Start the backend with: npm run start:dev');
    process.exit(1);
  }

  // Combine all participants
  const allParticipants = [
    ...(tournamentData.directInvites || []),
    ...(tournamentData.qualifiedTeams || []),
  ];

  if (allParticipants.length === 0) {
    console.log('\nNo participants found in tournament data.');
    console.log('The tournament might not have announced teams yet.');
    process.exit(0);
  }

  console.log(`\nTotal participants: ${allParticipants.length}`);
  allParticipants.forEach((p, i) => {
    console.log(`  ${i + 1}. ${p.teamName} (${p.players.length} players)`);
  });

  // Step 2: Update tournament record
  await updateTournament(tournamentData);

  // Step 3: Upsert teams
  const teamsData = await upsertTeams(allParticipants);

  // Step 4: Link teams to tournament
  await linkTeamsToTournament(allParticipants, teamsData);

  // Step 5: Upsert players
  const playersData = await upsertPlayers(allParticipants, teamsData);

  // Step 6: Link players to tournament
  await linkPlayersToTournament(playersData);

  // Step 7: Create sample matches
  await createSampleMatches(teamsData);

  // Print summary
  await printSummary();

  console.log('Seeding completed successfully!');
  console.log('You can now test the Tournament Detail screen with TI 2025 data.');
}

main().catch(console.error);
