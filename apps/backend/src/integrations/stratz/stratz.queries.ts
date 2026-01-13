// STRATZ GraphQL Queries

export const MATCH_STATS_QUERY = `
query GetMatchStats($matchId: Long!) {
  match(id: $matchId) {
    id
    didRadiantWin
    durationSeconds
    startDateTime
    endDateTime
    gameMode
    league {
      id
      displayName
      tier
    }
    series {
      id
      type
      teamOneId
      teamTwoId
      teamOneWinCount
      teamTwoWinCount
    }
    radiantTeam {
      id
      name
      tag
    }
    direTeam {
      id
      name
      tag
    }
    players {
      steamAccountId
      steamAccount {
        proSteamAccount {
          name
          realName
          team {
            id
            name
            tag
          }
          position
        }
      }
      isRadiant
      heroId
      position
      lane
      role
      kills
      deaths
      assists
      networth
      goldPerMinute
      experiencePerMinute
      numLastHits
      numDenies
      heroDamage
      towerDamage
      heroHealing
      item0Id
      item1Id
      item2Id
      item3Id
      item4Id
      item5Id
      imp
      award
      isVictory
      stats {
        campStack
        heroDamageReport {
          dealtTotal {
            stunDuration
            slowDuration
            disableDuration
          }
        }
        wards {
          type
        }
      }
    }
    pickBans {
      heroId
      order
      isPick
      isRadiant
    }
  }
}
`;

export const LEAGUE_MATCHES_QUERY = `
query GetLeagueMatches($leagueId: Int!, $take: Int!, $skip: Int!) {
  league(id: $leagueId) {
    id
    displayName
    tier
    region
    startDateTime
    endDateTime
    prizePool
    matches(request: { take: $take, skip: $skip }) {
      id
      didRadiantWin
      durationSeconds
      startDateTime
      series {
        id
        type
        teamOneId
        teamTwoId
        teamOneWinCount
        teamTwoWinCount
      }
      radiantTeam {
        id
        name
        tag
      }
      direTeam {
        id
        name
        tag
      }
    }
  }
}
`;

export const LEAGUE_INFO_QUERY = `
query GetLeagueInfo($leagueId: Int!) {
  league(id: $leagueId) {
    id
    displayName
    name
    tier
    region
    startDateTime
    endDateTime
    prizePool
    hasLiveMatches
    nodeGroups {
      id
      name
      nodeGroupType
      nodes {
        id
        name
        nodeType
        teamOneId
        teamTwoId
        teamOneWins
        teamTwoWins
        winningNodeId
        losingNodeId
        hasStarted
        isCompleted
        scheduledTime
        actualTime
        seriesId
      }
    }
    tables {
      leagueId
      tableTeams {
        teamId
        team {
          id
          name
          tag
        }
      }
    }
  }
}
`;

export const PRO_PLAYERS_QUERY = `
query GetProPlayers($take: Int = 500, $skip: Int = 0) {
  proSteamAccounts(request: { take: $take, skip: $skip }) {
    steamAccountId
    name
    realName
    team {
      id
      name
      tag
    }
    position
    birthday
    countries
    romanizedRealName
  }
}
`;

export const PLAYER_BY_STEAM_ID_QUERY = `
query GetPlayerBySteamId($steamAccountId: Long!) {
  player(steamAccountId: $steamAccountId) {
    steamAccountId
    proSteamAccount {
      name
      realName
      team {
        id
        name
        tag
      }
      position
      birthday
      countries
    }
    matchCount
    winCount
    firstMatchDate
    lastMatchDate
    behaviorScore
  }
}
`;

export const PLAYER_MATCHES_QUERY = `
query GetPlayerMatches($steamAccountId: Long!, $take: Int = 50, $leagueId: Int) {
  player(steamAccountId: $steamAccountId) {
    steamAccountId
    matches(request: {
      take: $take,
      orderBy: START_DATE_TIME,
      leagueId: $leagueId
    }) {
      id
      didRadiantWin
      durationSeconds
      startDateTime
      league {
        id
        displayName
      }
      players(steamAccountId: $steamAccountId) {
        heroId
        isRadiant
        kills
        deaths
        assists
        goldPerMinute
        experiencePerMinute
        numLastHits
        numDenies
        heroDamage
        towerDamage
        heroHealing
        isVictory
        imp
      }
    }
  }
}
`;

export const LIVE_MATCHES_QUERY = `
query GetLiveMatches {
  live {
    matches {
      matchId
      leagueId
      radiantTeamId
      direTeamId
      radiantScore
      direScore
      gameTime
      gameState
      isParsing
      radiantLead
      delay
      spectators
      completed
      players {
        steamAccountId
        heroId
        isRadiant
        numKills
        numDeaths
        numAssists
        numLastHits
        numDenies
        goldPerMinute
        experiencePerMinute
        networth
        level
      }
    }
  }
}
`;

export const LEAGUE_LIVE_MATCHES_QUERY = `
query GetLeagueLiveMatches($leagueId: Int!) {
  live {
    matches(request: { leagueId: $leagueId }) {
      matchId
      leagueId
      radiantTeamId
      direTeamId
      radiantScore
      direScore
      gameTime
      gameState
      isParsing
      radiantLead
      delay
      spectators
      completed
      players {
        steamAccountId
        heroId
        isRadiant
        numKills
        numDeaths
        numAssists
        numLastHits
        numDenies
        goldPerMinute
        experiencePerMinute
        networth
        level
      }
    }
  }
}
`;

export const TEAM_INFO_QUERY = `
query GetTeamInfo($teamId: Int!) {
  team(teamId: $teamId) {
    id
    name
    tag
    logo
    dateCreated
    countryCode
    url
    members {
      steamAccountId
      steamAccount {
        proSteamAccount {
          name
          realName
          position
        }
      }
      firstMatchId
      lastMatchId
    }
    matches(request: { take: 10, orderBy: START_DATE_TIME }) {
      id
      didRadiantWin
      durationSeconds
      startDateTime
      radiantTeam {
        id
        name
      }
      direTeam {
        id
        name
      }
    }
  }
}
`;

export const SERIES_MATCHES_QUERY = `
query GetSeriesMatches($seriesId: Long!) {
  series(id: $seriesId) {
    id
    type
    teamOneId
    teamTwoId
    teamOneWinCount
    teamTwoWinCount
    winningTeamId
    matches {
      id
      didRadiantWin
      durationSeconds
      startDateTime
      radiantTeam {
        id
        name
        tag
      }
      direTeam {
        id
        name
        tag
      }
      players {
        steamAccountId
        isRadiant
        heroId
        kills
        deaths
        assists
        goldPerMinute
        experiencePerMinute
        numLastHits
        numDenies
        heroDamage
        towerDamage
        heroHealing
        isVictory
        stats {
          campStack
          heroDamageReport {
            dealtTotal {
              stunDuration
            }
          }
          wards {
            type
          }
        }
      }
    }
  }
}
`;

export const MULTIPLE_MATCHES_QUERY = `
query GetMultipleMatches($matchIds: [Long!]!) {
  matches(ids: $matchIds) {
    id
    didRadiantWin
    durationSeconds
    startDateTime
    endDateTime
    league {
      id
      displayName
    }
    series {
      id
      type
      teamOneWinCount
      teamTwoWinCount
    }
    radiantTeam {
      id
      name
      tag
    }
    direTeam {
      id
      name
      tag
    }
    players {
      steamAccountId
      steamAccount {
        proSteamAccount {
          name
          team {
            name
          }
        }
      }
      isRadiant
      heroId
      position
      kills
      deaths
      assists
      goldPerMinute
      experiencePerMinute
      numLastHits
      numDenies
      heroDamage
      towerDamage
      heroHealing
      isVictory
      stats {
        campStack
        heroDamageReport {
          dealtTotal {
            stunDuration
          }
        }
        wards {
          type
        }
      }
    }
  }
}
`;
