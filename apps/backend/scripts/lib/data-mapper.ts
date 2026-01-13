/**
 * Data mapping utilities for transforming Liquipedia/STRATZ data to database schema
 */

import { v5 as uuidv5 } from 'uuid';

// Namespace for generating deterministic UUIDs
const UUID_NAMESPACE = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // DNS namespace

/**
 * Generate a deterministic UUID from a string
 * This ensures the same input always produces the same UUID
 */
export function generateDeterministicUuid(input: string): string {
  return uuidv5(input, UUID_NAMESPACE);
}

/**
 * Generate tournament UUID from Liquipedia page name
 */
export function generateTournamentId(pageName: string): string {
  return generateDeterministicUuid(`tournament:${pageName.toLowerCase()}`);
}

/**
 * Generate team UUID from team name
 */
export function generateTeamId(teamName: string): string {
  return generateDeterministicUuid(`team:${teamName.toLowerCase()}`);
}

/**
 * Generate player UUID from team name and nickname
 */
export function generatePlayerId(teamName: string, nickname: string): string {
  return generateDeterministicUuid(`player:${teamName.toLowerCase()}:${nickname.toLowerCase()}`);
}

/**
 * Map Liquipedia tier to database tier
 */
export function mapLiquipediaTier(liquipediaTier?: string): string {
  if (!liquipediaTier) return 'tier2';

  const tier = liquipediaTier.toLowerCase().trim();

  // Handle numeric tiers
  if (tier === '1') return 'tier1';
  if (tier === '2') return 'tier2';
  if (tier === '3') return 'tier3';
  if (tier === '4') return 'tier4';

  // Handle named tiers
  if (tier.includes('major')) return 'major';
  if (tier.includes('minor')) return 'tier2';

  return 'tier2'; // Default
}

/**
 * Map player position (1-5) to role string
 */
export function positionToRole(position?: number): string | undefined {
  switch (position) {
    case 1: return 'carry';
    case 2: return 'mid';
    case 3: return 'offlane';
    case 4: return 'support4';
    case 5: return 'support5';
    default: return undefined;
  }
}

/**
 * Infer region from qualifier/notes
 */
export function inferRegion(qualifier?: string, notes?: string): string | undefined {
  const text = `${qualifier || ''} ${notes || ''}`.toLowerCase();

  if (text.includes('western europe') || text.includes('weu')) return 'Western Europe';
  if (text.includes('eastern europe') || text.includes('eeu') || text.includes('cis')) return 'Eastern Europe';
  if (text.includes('china') || text.includes('cn')) return 'China';
  if (text.includes('sea') || text.includes('southeast asia')) return 'Southeast Asia';
  if (text.includes('north america') || text.includes('na')) return 'North America';
  if (text.includes('south america') || text.includes('sa')) return 'South America';
  if (text.includes('invited')) return 'International';

  return undefined;
}

/**
 * Generate team tag from team name
 */
export function generateTeamTag(teamName: string): string {
  // Handle some common team names specially
  const specialTags: Record<string, string> = {
    'Team Liquid': 'TL',
    'Team Secret': 'TS',
    'Team Spirit': 'TS',
    'Tundra Esports': 'TUN',
    'Gaimin Gladiators': 'GG',
    'OG': 'OG',
    'Nigma Galaxy': 'NGX',
    'BetBoom Team': 'BB',
    'Team Falcons': 'TF',
    'Xtreme Gaming': 'XG',
  };

  if (specialTags[teamName]) {
    return specialTags[teamName];
  }

  // Generate from first letters
  return teamName
    .split(/\s+/)
    .map(word => word[0])
    .join('')
    .toUpperCase()
    .slice(0, 4);
}

/**
 * Parse prize pool string to number
 */
export function parsePrizePool(prizePool?: string): number | undefined {
  if (!prizePool) return undefined;

  // Remove currency symbols and commas
  const cleaned = prizePool.replace(/[$,]/g, '').trim();

  // Extract number
  const match = cleaned.match(/[\d,]+\.?\d*/);
  if (!match) return undefined;

  const value = parseFloat(match[0].replace(/,/g, ''));
  return isNaN(value) ? undefined : value;
}

/**
 * Parse date string to ISO format
 */
export function parseDate(dateStr?: string): string | undefined {
  if (!dateStr) return undefined;

  try {
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return undefined;
    return date.toISOString();
  } catch {
    return undefined;
  }
}

/**
 * Determine tournament status based on dates
 */
export function determineTournamentStatus(
  startDate?: string,
  endDate?: string,
): 'upcoming' | 'ongoing' | 'completed' {
  const now = new Date();
  const start = startDate ? new Date(startDate) : null;
  const end = endDate ? new Date(endDate) : null;

  if (start && start > now) return 'upcoming';
  if (end && end < now) return 'completed';
  if (start && start <= now) return 'ongoing';

  return 'completed'; // Default to completed for historical imports
}

/**
 * Liquipedia types
 */
export interface LiquipediaPlayer {
  nickname: string;
  position?: number;
  country?: string;
  isSubstitute?: boolean;
}

export interface LiquipediaParticipant {
  teamName: string;
  players: LiquipediaPlayer[];
  coach?: string;
  qualifier?: string;
  placement?: string;
  notes?: string;
  logoUrl?: string;
  logoDarkUrl?: string;
}

export interface LiquipediaTournament {
  name: string;
  shortName?: string;
  tickerName?: string;
  pageName: string;
  tier?: string;
  valveTier?: string;
  type?: string;
  organizer?: string;
  sponsor?: string;
  series?: string;
  location?: string;
  venue?: string;
  format?: string;
  prizePool?: string;
  prizePoolUsd?: number;
  startDate?: string;
  endDate?: string;
  patch?: string;
  leagueId?: string;
  liquipediaUrl: string;
  participants?: number;
  winner?: string;
  runnerUp?: string;
  directInvites?: LiquipediaParticipant[];
  qualifiedTeams?: LiquipediaParticipant[];
}

/**
 * Database types for insert/upsert operations
 */
export interface DbTournament {
  id: string;
  name: string;
  tier: string;
  region?: string;
  status: 'upcoming' | 'ongoing' | 'completed';
  prize_pool?: number;
  start_date?: string;
  end_date?: string;
  logo_url?: string;
  liquipedia_url?: string;
  format?: string;
  created_at?: string;
  updated_at: string;
}

export interface DbTeam {
  id: string;
  name: string;
  tag: string;
  logo_url?: string;
  region?: string;
  liquipedia_url?: string;
  created_at?: string;
  updated_at: string;
}

export interface DbTournamentTeam {
  tournament_id: string;
  team_id: string;
  seed?: number;
  group_name?: string;
  placement?: number;
  prize_won?: number;
}

export interface DbPlayer {
  id: string;
  nickname: string;
  real_name?: string;
  role?: string;
  team_id?: string;
  country?: string;
  avatar_url?: string;
  stratz_id?: number;
  steam_id?: number;
  created_at?: string;
  updated_at: string;
}

export interface DbTournamentPlayer {
  tournament_id: string;
  player_id: string;
  team_id: string;
  is_active: boolean;
  fantasy_value?: number;
}

export interface DbMatch {
  id?: string;
  tournament_id: string;
  team1_id: string;
  team2_id: string;
  winner_id?: string;
  team1_score?: number;
  team2_score?: number;
  scheduled_at?: string;
  started_at?: string;
  ended_at?: string;
  stage?: string;
  round?: string;
  match_number?: number;
  best_of?: number;
  status: 'scheduled' | 'live' | 'completed';
  stream_url?: string;
  created_at?: string;
  updated_at: string;
}

/**
 * Determine tier based on tournament page name and Liquipedia tier
 */
function determineTier(pageName: string, liquipediaTier?: string): string {
  // The International is always "ti" tier
  if (pageName.toLowerCase().includes('the_international')) {
    return 'ti';
  }

  return mapLiquipediaTier(liquipediaTier);
}

/**
 * Map Liquipedia tournament data to database format
 */
export function mapTournamentToDb(
  tournament: LiquipediaTournament,
  logoUrl?: string,
): DbTournament {
  const tournamentId = generateTournamentId(tournament.pageName);

  return {
    id: tournamentId,
    name: tournament.name,
    tier: determineTier(tournament.pageName, tournament.tier),
    region: tournament.location?.split(',')[0]?.trim(),
    status: determineTournamentStatus(tournament.startDate, tournament.endDate),
    prize_pool: tournament.prizePoolUsd ?? parsePrizePool(tournament.prizePool),
    start_date: parseDate(tournament.startDate),
    end_date: parseDate(tournament.endDate),
    logo_url: logoUrl,
    liquipedia_url: tournament.liquipediaUrl,
    format: tournament.format,
    updated_at: new Date().toISOString(),
  };
}

/**
 * Map Liquipedia participant to database team format
 */
export function mapTeamToDb(participant: LiquipediaParticipant): DbTeam {
  const teamId = generateTeamId(participant.teamName);

  return {
    id: teamId,
    name: participant.teamName,
    tag: generateTeamTag(participant.teamName),
    logo_url: participant.logoUrl,
    region: inferRegion(participant.qualifier, participant.notes),
    liquipedia_url: `https://liquipedia.net/dota2/${encodeURIComponent(participant.teamName.replace(/ /g, '_'))}`,
    updated_at: new Date().toISOString(),
  };
}

/**
 * Map participant to tournament_teams junction table
 */
export function mapTournamentTeamToDb(
  tournamentId: string,
  participant: LiquipediaParticipant,
  index: number,
  totalTeams: number,
): DbTournamentTeam {
  const teamId = generateTeamId(participant.teamName);

  // Parse placement if available (e.g., "1st", "2nd-3rd")
  let placement: number | undefined;
  if (participant.placement) {
    const match = participant.placement.match(/\d+/);
    if (match) {
      placement = parseInt(match[0], 10);
    }
  }

  // Assign group based on index (typical TI format)
  const groupName = index < Math.ceil(totalTeams / 2) ? 'Group A' : 'Group B';

  return {
    tournament_id: tournamentId,
    team_id: teamId,
    seed: index + 1,
    group_name: groupName,
    placement,
  };
}

/**
 * Map Liquipedia player to database format
 */
export function mapPlayerToDb(
  player: LiquipediaPlayer,
  teamName: string,
  teamId: string,
): DbPlayer {
  const playerId = generatePlayerId(teamName, player.nickname);

  return {
    id: playerId,
    nickname: player.nickname,
    role: positionToRole(player.position),
    team_id: teamId,
    country: player.country,
    updated_at: new Date().toISOString(),
  };
}

/**
 * Map player to tournament_players junction table
 */
export function mapTournamentPlayerToDb(
  tournamentId: string,
  playerId: string,
  teamId: string,
): DbTournamentPlayer {
  return {
    tournament_id: tournamentId,
    player_id: playerId,
    team_id: teamId,
    is_active: true,
    fantasy_value: 100, // Default value
  };
}
