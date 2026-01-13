// STRATZ API Types
// GraphQL API: https://api.stratz.com/graphql

// ============ Player Types ============

export interface StratzProPlayer {
  steamAccountId: number;
  name: string;
  realName?: string;
  team?: {
    id: number;
    name: string;
    tag: string;
    logo?: string;
  };
  position?: StratzPosition;
  birthday?: number;
  countries?: string[];
  roles?: number;
  romanizedRealName?: string;
}

export interface StratzPlayer {
  steamAccountId: number;
  proSteamAccount?: StratzProPlayer;
  matchCount?: number;
  winCount?: number;
  firstMatchDate?: number;
  lastMatchDate?: number;
  performance?: {
    kills?: number;
    deaths?: number;
    assists?: number;
  };
  behaviorScore?: number;
}

export enum StratzPosition {
  POSITION_1 = 'POSITION_1', // Carry
  POSITION_2 = 'POSITION_2', // Mid
  POSITION_3 = 'POSITION_3', // Offlane
  POSITION_4 = 'POSITION_4', // Soft Support
  POSITION_5 = 'POSITION_5', // Hard Support
  UNKNOWN = 'UNKNOWN',
}

// ============ Match Types ============

export interface StratzMatch {
  id: number;
  didRadiantWin: boolean;
  durationSeconds: number;
  startDateTime?: number;
  endDateTime?: number;
  gameMode?: number;
  lobbyType?: number;
  league?: {
    id: number;
    displayName?: string;
    tier?: string;
  };
  series?: {
    id: number;
    type: number; // 0=Bo1, 1=Bo3, 2=Bo5
    teamOneId?: number;
    teamTwoId?: number;
    teamOneWinCount?: number;
    teamTwoWinCount?: number;
  };
  radiantTeam?: StratzTeam;
  direTeam?: StratzTeam;
  players: StratzMatchPlayer[];
  pickBans?: StratzPickBan[];
  statsDateTime?: number;
}

export interface StratzTeam {
  id: number;
  name: string;
  tag?: string;
  logo?: string;
}

export interface StratzMatchPlayer {
  steamAccountId: number;
  steamAccount?: {
    proSteamAccount?: StratzProPlayer;
  };
  isRadiant: boolean;
  heroId: number;
  position?: StratzPosition;
  lane?: number;
  role?: number;
  // Core stats
  kills: number;
  deaths: number;
  assists: number;
  networth: number;
  goldPerMinute: number;
  experiencePerMinute: number;
  numLastHits: number;
  numDenies: number;
  // Damage stats
  heroDamage: number;
  towerDamage: number;
  heroHealing: number;
  // Items
  item0Id?: number;
  item1Id?: number;
  item2Id?: number;
  item3Id?: number;
  item4Id?: number;
  item5Id?: number;
  backpack0Id?: number;
  backpack1Id?: number;
  backpack2Id?: number;
  neutral0Id?: number;
  // Additional stats
  imp?: number; // Individual Match Performance score
  award?: string;
  isVictory: boolean;
  stats?: StratzPlayerStats;
}

export interface StratzPlayerStats {
  campStack?: number[];
  wardDestruction?: Array<{ isWard: boolean }>;
  matchPlayerBuffEvent?: Array<{
    itemId?: number;
    stackCount?: number;
    time: number;
  }>;
  heroDamageReport?: {
    dealtTotal?: {
      stunDuration?: number;
      slowDuration?: number;
      disableDuration?: number;
    };
  };
  runes?: Array<{ rune: number; time: number }>;
  sentryDestroyed?: number;
  wards?: Array<{
    type: 'OBSERVER' | 'SENTRY';
    time?: number;
    positionX?: number;
    positionY?: number;
  }>;
}

export interface StratzPickBan {
  heroId: number;
  order: number;
  isPick: boolean;
  isRadiant: boolean;
  bannedHeroId?: number;
}

// ============ League Types ============

export interface StratzLeague {
  id: number;
  displayName?: string;
  name?: string;
  tier?: StratzLeagueTier;
  region?: StratzRegion;
  startDateTime?: number;
  endDateTime?: number;
  prizePool?: number;
  hasLiveMatches?: boolean;
  matches?: StratzMatch[];
  nodeGroups?: StratzNodeGroup[];
  tables?: StratzLeagueTable[];
  streams?: StratzStream[];
}

export enum StratzLeagueTier {
  AMATEUR = 'AMATEUR',
  PROFESSIONAL = 'PROFESSIONAL',
  MINOR = 'MINOR',
  MAJOR = 'MAJOR',
  INTERNATIONAL = 'INTERNATIONAL',
  DPC_QUALIFIER = 'DPC_QUALIFIER',
  DPC_LEAGUE_QUALIFIER = 'DPC_LEAGUE_QUALIFIER',
  DPC_LEAGUE = 'DPC_LEAGUE',
}

export enum StratzRegion {
  CHINA = 'CHINA',
  SEA = 'SEA',
  NORTH_AMERICA = 'NORTH_AMERICA',
  SOUTH_AMERICA = 'SOUTH_AMERICA',
  EUROPE = 'EUROPE',
  CIS = 'CIS',
}

export interface StratzNodeGroup {
  id?: string;
  name?: string;
  nodeGroupType?: string;
  nodes?: StratzNode[];
}

export interface StratzNode {
  id?: string;
  name?: string;
  nodeType?: string;
  teamOneId?: number;
  teamTwoId?: number;
  teamOneWins?: number;
  teamTwoWins?: number;
  winningNodeId?: number;
  losingNodeId?: number;
  hasStarted?: boolean;
  isCompleted?: boolean;
  scheduledTime?: number;
  actualTime?: number;
  seriesId?: number;
  matches?: StratzMatch[];
}

export interface StratzLeagueTable {
  leagueId?: number;
  tableTeams?: StratzTableTeam[];
}

export interface StratzTableTeam {
  teamId: number;
  team?: StratzTeam;
  standings?: {
    matchWins?: number;
    matchLosses?: number;
    gameWins?: number;
    gameLosses?: number;
    points?: number;
  };
}

export interface StratzStream {
  id?: number;
  languageId?: string;
  name?: string;
  broadcastProvider?: string;
  streamUrl?: string;
}

// ============ Live Match Types ============

export interface StratzLiveMatch {
  matchId: number;
  leagueId?: number;
  radiantTeamId?: number;
  direTeamId?: number;
  radiantScore?: number;
  direScore?: number;
  gameTime?: number;
  gameState?: number;
  isParsing?: boolean;
  radiantLead?: number;
  averageRank?: number;
  delay?: number;
  spectators?: number;
  completed?: boolean;
  players?: StratzLivePlayer[];
}

export interface StratzLivePlayer {
  steamAccountId: number;
  heroId: number;
  isRadiant: boolean;
  numKills?: number;
  numDeaths?: number;
  numAssists?: number;
  numLastHits?: number;
  numDenies?: number;
  goldPerMinute?: number;
  experiencePerMinute?: number;
  networth?: number;
  level?: number;
}

// ============ Response Types ============

export interface StratzGraphQLResponse<T> {
  data?: T;
  errors?: Array<{
    message: string;
    locations?: Array<{ line: number; column: number }>;
    path?: string[];
  }>;
}

// ============ Mapped Types for Our App ============

export interface PlayerMatchStats {
  playerId: string; // Our internal player ID
  steamAccountId: number;
  matchId: number;
  gameNumber: number;
  // Core stats
  kills: number;
  deaths: number;
  assists: number;
  lastHits: number;
  denies: number;
  gpm: number;
  xpm: number;
  // Damage stats
  heroDamage: number;
  towerDamage: number;
  heroHealing: number;
  // Support stats
  stuns: number;
  obsPlaced: number;
  campsStacked: number;
  // Other
  firstBlood: boolean;
  heroId: number;
  isWinner: boolean;
  isRadiant: boolean;
}

export interface LeagueMatchSummary {
  matchId: number;
  radiantTeam: {
    id: number;
    name: string;
    tag?: string;
  };
  direTeam: {
    id: number;
    name: string;
    tag?: string;
  };
  radiantWin: boolean;
  durationSeconds: number;
  startDateTime: number;
  seriesId?: number;
  seriesType?: number; // Bo1, Bo3, Bo5
}

export interface ProPlayerMapping {
  steamAccountId: number;
  name: string;
  realName?: string;
  teamId?: number;
  teamName?: string;
  teamTag?: string;
  position?: string;
  country?: string;
}
