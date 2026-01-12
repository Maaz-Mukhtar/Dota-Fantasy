// Liquipedia API Types

export interface LiquipediaApiResponse {
  parse?: {
    title: string;
    pageid: number;
    wikitext?: {
      '*': string;
    };
    text?: {
      '*': string;
    };
    categories?: Array<{ '*': string }>;
    links?: Array<{ '*': string }>;
  };
  query?: {
    pages?: Record<
      string,
      {
        pageid: number;
        ns: number;
        title: string;
        revisions?: Array<{
          '*': string;
        }>;
      }
    >;
    categorymembers?: Array<{
      pageid: number;
      ns: number;
      title: string;
    }>;
  };
  error?: {
    code: string;
    info: string;
  };
}

export interface TournamentInfo {
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
  teams?: TournamentTeam[];
  participants?: number;
  winner?: string;
  runnerUp?: string;
  // Enhanced data
  directInvites?: TournamentParticipant[];
  qualifiedTeams?: TournamentParticipant[];
  prizeDistribution?: PrizeSlot[];
}

export interface TournamentParticipant {
  teamName: string;
  players: ParticipantPlayer[];
  coach?: string;
  qualifier?: string; // "Invited" or region qualifier name
  placement?: string;
  notes?: string;
  logoUrl?: string;
  logoDarkUrl?: string;
}

export interface ParticipantPlayer {
  nickname: string;
  position?: number; // 1-5
  country?: string;
  isSubstitute?: boolean;
}

export interface PrizeSlot {
  place: string;
  usdPrize?: number;
  percentage?: string;
  team?: string;
}

export interface TournamentTeam {
  name: string;
  pageName?: string;
  placement?: string;
  prizeWon?: string;
  region?: string;
}

export interface TeamInfo {
  name: string;
  pageName: string;
  region?: string;
  location?: string;
  captain?: string;
  coach?: string;
  manager?: string;
  sponsor?: string;
  liquipediaUrl: string;
  roster?: PlayerInfo[];
  earnings?: string;
  created?: string;
}

export interface PlayerInfo {
  nickname: string;
  realName?: string;
  pageName?: string;
  country?: string;
  role?: string;
  team?: string;
  romanizedName?: string;
  birthDate?: string;
  liquipediaUrl?: string;
}

export interface MatchInfo {
  team1: string;
  team2: string;
  score1?: number;
  score2?: number;
  winner?: string;
  date?: string;
  tournament?: string;
  format?: string;
  stage?: string;
}

export interface ParsedInfobox {
  [key: string]: string | undefined;
}

// ============ Match Stage Types ============

export type TournamentStage = 'group_stage' | 'playoffs';

export type PlayoffRound =
  | 'upper_bracket_r1'
  | 'upper_bracket_qf'
  | 'upper_bracket_sf'
  | 'upper_bracket_final'
  | 'lower_bracket_r1'
  | 'lower_bracket_r2'
  | 'lower_bracket_r3'
  | 'lower_bracket_qf'
  | 'lower_bracket_sf'
  | 'lower_bracket_final'
  | 'grand_final'
  | 'placement'
  | 'tiebreaker'
  | 'unknown';

export interface MatchStageInfo {
  matchId: number;
  stage: TournamentStage;
  substage: string; // 'Group A', 'Upper Bracket QF', 'Grand Final', etc.
  round?: PlayoffRound; // Normalized round identifier
  pageSource: string; // Which Liquipedia page it came from
  seriesFormat?: 'bo1' | 'bo2' | 'bo3' | 'bo5';
  gameNumber?: number; // 1, 2, or 3 within the series
  team1?: string;
  team2?: string;
  date?: string;
}

export interface SeriesStageInfo {
  seriesId?: string; // Liquipedia series ID if available
  stage: TournamentStage;
  substage: string;
  round?: PlayoffRound;
  pageSource: string;
  seriesFormat: 'bo1' | 'bo2' | 'bo3' | 'bo5';
  matchIds: number[]; // All match IDs in this series
  team1?: string;
  team2?: string;
  date?: string;
}

export interface TournamentStageMapping {
  tournamentPath: string;
  leagueId?: number;
  matches: Map<number, MatchStageInfo>;
  series: SeriesStageInfo[];
  groupStageMatchCount: number;
  playoffMatchCount: number;
}
