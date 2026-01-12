import { Injectable, Logger } from '@nestjs/common';
import { LiquipediaService } from './liquipedia.service';
import {
  MatchStageInfo,
  SeriesStageInfo,
  TournamentStageMapping,
  TournamentStage,
  PlayoffRound,
} from './liquipedia.types';

interface ParsedMatch {
  matchIds: number[];
  team1?: string;
  team2?: string;
  date?: string;
  bestOf?: number;
}

interface ParsedMatchlist {
  title: string;
  id: string;
  matches: ParsedMatch[];
}

interface ParsedBracketMatch {
  roundCode: string; // R2M1, R4M1, etc.
  roundName: string; // From comments like <!-- Upper Bracket Quarterfinals -->
  match: ParsedMatch;
}

@Injectable()
export class LiquipediaMatchStageService {
  private readonly logger = new Logger(LiquipediaMatchStageService.name);

  constructor(private readonly liquipediaService: LiquipediaService) {}

  /**
   * Get complete stage mapping for a tournament
   * Uses hybrid approach: wikitext first, HTML fallback for LPDB-based tournaments
   * @param tournamentPath - Base path like "The_International/2024"
   */
  async getTournamentStageMapping(
    tournamentPath: string,
  ): Promise<TournamentStageMapping> {
    this.logger.log(`Building stage mapping for: ${tournamentPath}`);

    const matches = new Map<number, MatchStageInfo>();
    const series: SeriesStageInfo[] = [];
    let groupStageMatchCount = 0;
    let playoffMatchCount = 0;

    // Try to get league ID from main tournament page
    let leagueId: number | undefined;
    try {
      const mainWikitext =
        await this.liquipediaService.getPageWikitext(tournamentPath);
      const leagueIdMatch = mainWikitext.match(/\|leagueid\s*=\s*(\d+)/i);
      if (leagueIdMatch) {
        leagueId = parseInt(leagueIdMatch[1], 10);
      }
    } catch (e) {
      this.logger.warn(`Could not fetch main tournament page: ${e}`);
    }

    // 1. Try wikitext parsing first (works for TI 2023 style with inline match data)
    const groupStagePath = `${tournamentPath}/Group_Stage`;
    const mainEventPath = `${tournamentPath}/Main_Event`;

    // Parse Group Stage from wikitext
    try {
      const groupStageWikitext =
        await this.liquipediaService.getPageWikitext(groupStagePath);

      if (groupStageWikitext) {
        const groupMatches = this.parseGroupStage(
          groupStageWikitext,
          groupStagePath,
        );

        for (const seriesInfo of groupMatches) {
          series.push(seriesInfo);
          for (let i = 0; i < seriesInfo.matchIds.length; i++) {
            const matchId = seriesInfo.matchIds[i];
            matches.set(matchId, {
              matchId,
              stage: 'group_stage',
              substage: seriesInfo.substage,
              round: seriesInfo.round,
              pageSource: groupStagePath,
              seriesFormat: seriesInfo.seriesFormat,
              gameNumber: i + 1,
              team1: seriesInfo.team1,
              team2: seriesInfo.team2,
              date: seriesInfo.date,
            });
            groupStageMatchCount++;
          }
        }
        this.logger.log(
          `Wikitext: Parsed ${groupStageMatchCount} group stage matches from ${groupMatches.length} series`,
        );
      }
    } catch (e) {
      this.logger.warn(`Could not fetch Group Stage wikitext: ${e}`);
    }

    // Parse Main Event from wikitext
    try {
      const mainEventWikitext =
        await this.liquipediaService.getPageWikitext(mainEventPath);

      if (mainEventWikitext) {
        const playoffMatches = this.parseMainEvent(
          mainEventWikitext,
          mainEventPath,
        );

        for (const seriesInfo of playoffMatches) {
          series.push(seriesInfo);
          for (let i = 0; i < seriesInfo.matchIds.length; i++) {
            const matchId = seriesInfo.matchIds[i];
            matches.set(matchId, {
              matchId,
              stage: 'playoffs',
              substage: seriesInfo.substage,
              round: seriesInfo.round,
              pageSource: mainEventPath,
              seriesFormat: seriesInfo.seriesFormat,
              gameNumber: i + 1,
              team1: seriesInfo.team1,
              team2: seriesInfo.team2,
              date: seriesInfo.date,
            });
            playoffMatchCount++;
          }
        }
        this.logger.log(
          `Wikitext: Parsed ${playoffMatchCount} playoff matches from ${playoffMatches.length} series`,
        );
      }
    } catch (e) {
      this.logger.warn(`Could not fetch Main Event wikitext: ${e}`);
    }

    // 2. If wikitext parsing found no matches, try HTML parsing (LPDB-based tournaments like TI 2025)
    if (matches.size === 0) {
      this.logger.log(
        'No matches found in wikitext, trying HTML parsing (LPDB fallback)...',
      );

      // Parse Group Stage from rendered HTML
      try {
        const groupStageHtml =
          await this.liquipediaService.parsePage(groupStagePath);

        if (groupStageHtml) {
          const groupMatches = this.parseGroupStageHtml(
            groupStageHtml,
            groupStagePath,
          );

          for (const seriesInfo of groupMatches) {
            series.push(seriesInfo);
            for (let i = 0; i < seriesInfo.matchIds.length; i++) {
              const matchId = seriesInfo.matchIds[i];
              matches.set(matchId, {
                matchId,
                stage: 'group_stage',
                substage: seriesInfo.substage,
                round: seriesInfo.round,
                pageSource: groupStagePath,
                seriesFormat: seriesInfo.seriesFormat,
                gameNumber: i + 1,
                team1: seriesInfo.team1,
                team2: seriesInfo.team2,
                date: seriesInfo.date,
              });
              groupStageMatchCount++;
            }
          }
          this.logger.log(
            `HTML: Parsed ${groupStageMatchCount} group stage matches from ${groupMatches.length} series`,
          );
        }
      } catch (e) {
        this.logger.warn(`Could not fetch Group Stage HTML: ${e}`);
      }

      // Parse Main Event from rendered HTML
      try {
        const mainEventHtml =
          await this.liquipediaService.parsePage(mainEventPath);

        if (mainEventHtml) {
          const playoffMatches = this.parseMainEventHtml(
            mainEventHtml,
            mainEventPath,
          );

          for (const seriesInfo of playoffMatches) {
            series.push(seriesInfo);
            for (let i = 0; i < seriesInfo.matchIds.length; i++) {
              const matchId = seriesInfo.matchIds[i];
              matches.set(matchId, {
                matchId,
                stage: 'playoffs',
                substage: seriesInfo.substage,
                round: seriesInfo.round,
                pageSource: mainEventPath,
                seriesFormat: seriesInfo.seriesFormat,
                gameNumber: i + 1,
                team1: seriesInfo.team1,
                team2: seriesInfo.team2,
                date: seriesInfo.date,
              });
              playoffMatchCount++;
            }
          }
          this.logger.log(
            `HTML: Parsed ${playoffMatchCount} playoff matches from ${playoffMatches.length} series`,
          );
        }
      } catch (e) {
        this.logger.warn(`Could not fetch Main Event HTML: ${e}`);
      }
    }

    // 3. Try alternative paths if still no matches found
    if (matches.size === 0) {
      const altPaths = [
        `${tournamentPath}/Group_Stage_1`,
        `${tournamentPath}/Group_Stage_2`,
        `${tournamentPath}/Playoffs`,
        `${tournamentPath}/Bracket`,
      ];

      for (const altPath of altPaths) {
        try {
          const wikitext =
            await this.liquipediaService.getPageWikitext(altPath);
          if (wikitext && wikitext.includes('matchid')) {
            this.logger.log(`Found matches in alternative path: ${altPath}`);
            const isGroupStage = altPath.toLowerCase().includes('group');
            const parsedMatches = isGroupStage
              ? this.parseGroupStage(wikitext, altPath)
              : this.parseMainEvent(wikitext, altPath);

            for (const seriesInfo of parsedMatches) {
              series.push(seriesInfo);
              for (let i = 0; i < seriesInfo.matchIds.length; i++) {
                const matchId = seriesInfo.matchIds[i];
                matches.set(matchId, {
                  matchId,
                  stage: isGroupStage ? 'group_stage' : 'playoffs',
                  substage: seriesInfo.substage,
                  round: seriesInfo.round,
                  pageSource: altPath,
                  seriesFormat: seriesInfo.seriesFormat,
                  gameNumber: i + 1,
                  team1: seriesInfo.team1,
                  team2: seriesInfo.team2,
                  date: seriesInfo.date,
                });
                if (isGroupStage) {
                  groupStageMatchCount++;
                } else {
                  playoffMatchCount++;
                }
              }
            }
          }
        } catch {
          // Page doesn't exist, continue
        }
      }
    }

    return {
      tournamentPath,
      leagueId,
      matches,
      series,
      groupStageMatchCount,
      playoffMatchCount,
    };
  }

  /**
   * Parse group stage wikitext to extract match info
   */
  private parseGroupStage(
    wikitext: string,
    pageSource: string,
  ): SeriesStageInfo[] {
    const series: SeriesStageInfo[] = [];

    // Check for Elimination Round section (TI 2025 format)
    // This section uses a Bracket template within the Group Stage page
    const eliminationRoundMatches = this.parseEliminationRound(wikitext, pageSource);
    const eliminationMatchIds = new Set<number>();
    for (const elim of eliminationRoundMatches) {
      series.push(elim);
      elim.matchIds.forEach((id) => eliminationMatchIds.add(id));
    }

    // Parse Matchlist templates (regular group stage rounds)
    const matchlists = this.parseMatchlists(wikitext);

    for (const matchlist of matchlists) {
      for (const match of matchlist.matches) {
        if (match.matchIds.length > 0) {
          // Skip if already added as elimination round
          if (match.matchIds.some((id) => eliminationMatchIds.has(id))) {
            continue;
          }
          series.push({
            stage: 'group_stage',
            substage: matchlist.title,
            pageSource,
            seriesFormat: this.getBestOfFormat(match.bestOf || match.matchIds.length),
            matchIds: match.matchIds,
            team1: match.team1,
            team2: match.team2,
            date: match.date,
          });
        }
      }
    }

    // Also parse any standalone Match templates not in Matchlists
    const standaloneMatches = this.parseStandaloneMatches(wikitext);
    for (const match of standaloneMatches) {
      if (match.matchIds.length > 0) {
        // Check if already added via Matchlist or Elimination Round
        const alreadyAdded = series.some((s) =>
          s.matchIds.some((id) => match.matchIds.includes(id)),
        );
        if (!alreadyAdded) {
          series.push({
            stage: 'group_stage',
            substage: 'Group Stage',
            pageSource,
            seriesFormat: this.getBestOfFormat(match.bestOf || match.matchIds.length),
            matchIds: match.matchIds,
            team1: match.team1,
            team2: match.team2,
            date: match.date,
          });
        }
      }
    }

    return series;
  }

  /**
   * Parse Elimination Round bracket from Group Stage page (TI 2025 format)
   * These are matches in a {{Bracket}} template under the "Elimination Round" section
   */
  private parseEliminationRound(
    wikitext: string,
    pageSource: string,
  ): SeriesStageInfo[] {
    const series: SeriesStageInfo[] = [];

    // Look for Elimination Round section marker
    // Format: =={{Stage|Elimination Round}}== or ==Elimination Round==
    const eliminationSectionPattern = /={2,}\s*\{\{Stage\|Elimination Round\}\}\s*={2,}|={2,}\s*Elimination Round\s*={2,}/i;
    const sectionMatch = eliminationSectionPattern.exec(wikitext);

    if (!sectionMatch) {
      return series;
    }

    // Extract content from Elimination Round section to end of page or next major section
    const sectionStart = sectionMatch.index;
    const nextSectionMatch = wikitext.substring(sectionStart + sectionMatch[0].length).match(/\n={2}[^=]/);
    const sectionEnd = nextSectionMatch
      ? sectionStart + sectionMatch[0].length + nextSectionMatch.index!
      : wikitext.length;

    const eliminationContent = wikitext.substring(sectionStart, sectionEnd);

    // Find Bracket template in this section
    const bracketStart = eliminationContent.indexOf('{{Bracket');
    if (bracketStart === -1) {
      return series;
    }

    // Use brace balancing to find the end of the Bracket template
    let depth = 0;
    let bracketEnd = bracketStart;
    for (let i = bracketStart; i < eliminationContent.length - 1; i++) {
      if (eliminationContent[i] === '{' && eliminationContent[i + 1] === '{') {
        depth++;
        i++;
      } else if (eliminationContent[i] === '}' && eliminationContent[i + 1] === '}') {
        depth--;
        i++;
        if (depth === 0) {
          bracketEnd = i + 1;
          break;
        }
      }
    }

    const bracketContent = eliminationContent.substring(bracketStart, bracketEnd);

    // Parse matches from the bracket
    // Format: |R1M1={{Match...}}
    const matchPattern = /\|(R\d+M\d+)=\{\{Match/gi;
    let matchStart;

    while ((matchStart = matchPattern.exec(bracketContent)) !== null) {
      const roundCode = matchStart[1];

      // Find the start of the {{Match template
      const templateStart = bracketContent.indexOf('{{Match', matchStart.index);
      if (templateStart === -1) continue;

      // Use brace balancing to find the end
      let matchDepth = 0;
      let templateEnd = templateStart;
      for (let i = templateStart; i < bracketContent.length - 1; i++) {
        if (bracketContent[i] === '{' && bracketContent[i + 1] === '{') {
          matchDepth++;
          i++;
        } else if (bracketContent[i] === '}' && bracketContent[i + 1] === '}') {
          matchDepth--;
          i++;
          if (matchDepth === 0) {
            templateEnd = i + 1;
            break;
          }
        }
      }

      const matchContent = bracketContent.substring(templateStart, templateEnd);
      const parsed = this.parseMatchTemplate(matchContent);

      if (parsed.matchIds.length > 0) {
        series.push({
          stage: 'group_stage',
          substage: 'Elimination Round',
          round: 'tiebreaker', // Elimination rounds are essentially tiebreakers
          pageSource,
          seriesFormat: this.getBestOfFormat(parsed.bestOf || parsed.matchIds.length),
          matchIds: parsed.matchIds,
          team1: parsed.team1,
          team2: parsed.team2,
          date: parsed.date,
        });
      }
    }

    this.logger.log(`Parsed ${series.length} elimination round series from Group Stage`);
    return series;
  }

  /**
   * Parse main event/playoff wikitext to extract match info
   */
  private parseMainEvent(
    wikitext: string,
    pageSource: string,
  ): SeriesStageInfo[] {
    const series: SeriesStageInfo[] = [];

    // Parse Bracket templates with round information from comments
    const bracketMatches = this.parseBracket(wikitext);

    for (const bracketMatch of bracketMatches) {
      if (bracketMatch.match.matchIds.length > 0) {
        const round = this.normalizePlayoffRound(bracketMatch.roundName);
        series.push({
          stage: 'playoffs',
          substage: bracketMatch.roundName || this.roundCodeToName(bracketMatch.roundCode),
          round,
          pageSource,
          seriesFormat: this.getBestOfFormat(
            bracketMatch.match.bestOf || bracketMatch.match.matchIds.length,
          ),
          matchIds: bracketMatch.match.matchIds,
          team1: bracketMatch.match.team1,
          team2: bracketMatch.match.team2,
          date: bracketMatch.match.date,
        });
      }
    }

    // Also check for Matchlists in playoffs (tiebreakers, placements)
    const matchlists = this.parseMatchlists(wikitext);
    for (const matchlist of matchlists) {
      for (const match of matchlist.matches) {
        if (match.matchIds.length > 0) {
          const alreadyAdded = series.some((s) =>
            s.matchIds.some((id) => match.matchIds.includes(id)),
          );
          if (!alreadyAdded) {
            const round = this.normalizePlayoffRound(matchlist.title);
            series.push({
              stage: 'playoffs',
              substage: matchlist.title,
              round,
              pageSource,
              seriesFormat: this.getBestOfFormat(match.bestOf || match.matchIds.length),
              matchIds: match.matchIds,
              team1: match.team1,
              team2: match.team2,
              date: match.date,
            });
          }
        }
      }
    }

    return series;
  }

  /**
   * Parse {{Matchlist}} templates from wikitext using brace balancing
   */
  private parseMatchlists(wikitext: string): ParsedMatchlist[] {
    const matchlists: ParsedMatchlist[] = [];

    // Find all Matchlist template starts
    const matchlistPattern = /\{\{Matchlist\|/gi;
    let match;

    while ((match = matchlistPattern.exec(wikitext)) !== null) {
      const startIndex = match.index;

      // Use brace balancing to find the end of the Matchlist template
      let depth = 0;
      let endIndex = startIndex;
      for (let i = startIndex; i < wikitext.length - 1; i++) {
        if (wikitext[i] === '{' && wikitext[i + 1] === '{') {
          depth++;
          i++;
        } else if (wikitext[i] === '}' && wikitext[i + 1] === '}') {
          depth--;
          i++;
          if (depth === 0) {
            endIndex = i + 1;
            break;
          }
        }
      }

      const content = wikitext.substring(startIndex, endIndex);

      // Extract title and id
      const titleMatch = content.match(/title=([^|}\n]+)/);
      const idMatch = content.match(/\|id=([^|}\n]+)/);

      const title = titleMatch ? titleMatch[1].trim() : 'Unknown';
      const id = idMatch ? idMatch[1].trim() : '';

      // Extract all Match templates within this Matchlist
      const matches = this.extractMatchesFromMatchlist(content);

      if (matches.length > 0) {
        matchlists.push({ title, id, matches });
      }
    }

    return matchlists;
  }

  /**
   * Extract Match templates from a Matchlist using brace balancing
   */
  private extractMatchesFromMatchlist(content: string): ParsedMatch[] {
    const matches: ParsedMatch[] = [];

    // Find Match template starts: |M1={{Match or |M1header={{Match
    const matchPattern = /\|M\d+(?:header)?=\{\{Match/gi;
    let matchStart;

    while ((matchStart = matchPattern.exec(content)) !== null) {
      // Find the start of the {{Match
      const templateStart = content.indexOf('{{Match', matchStart.index);
      if (templateStart === -1) continue;

      // Use brace balancing to find the end
      let depth = 0;
      let templateEnd = templateStart;
      for (let i = templateStart; i < content.length - 1; i++) {
        if (content[i] === '{' && content[i + 1] === '{') {
          depth++;
          i++;
        } else if (content[i] === '}' && content[i + 1] === '}') {
          depth--;
          i++;
          if (depth === 0) {
            templateEnd = i + 1;
            break;
          }
        }
      }

      const matchContent = content.substring(templateStart, templateEnd);
      const parsed = this.parseMatchTemplate(matchContent);
      if (parsed.matchIds.length > 0) {
        matches.push(parsed);
      }
    }

    return matches;
  }

  /**
   * Parse {{Bracket}} templates with round comments
   */
  private parseBracket(wikitext: string): ParsedBracketMatch[] {
    const bracketMatches: ParsedBracketMatch[] = [];

    // Find Bracket template
    const bracketStart = wikitext.indexOf('{{Bracket');
    if (bracketStart === -1) return bracketMatches;

    // Find the end of the Bracket template (matching braces)
    let depth = 0;
    let bracketEnd = bracketStart;
    for (let i = bracketStart; i < wikitext.length - 1; i++) {
      if (wikitext[i] === '{' && wikitext[i + 1] === '{') {
        depth++;
        i++;
      } else if (wikitext[i] === '}' && wikitext[i + 1] === '}') {
        depth--;
        i++;
        if (depth === 0) {
          bracketEnd = i + 1;
          break;
        }
      }
    }

    const bracketContent = wikitext.substring(bracketStart, bracketEnd);

    // Parse round comments and matches
    // Comments look like: <!-- Upper Bracket Quarterfinals -->
    // Followed by: |R2M1={{Match...}}
    const lines = bracketContent.split('\n');
    let currentRoundName = '';

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();

      // Check for round comment
      const commentMatch = line.match(/<!--\s*([^>]+)\s*-->/);
      if (commentMatch) {
        currentRoundName = commentMatch[1].trim();
        continue;
      }

      // Check for match definition
      const matchDefMatch = line.match(/\|(R\d+M\d+)=\{\{Match/);
      if (matchDefMatch) {
        const roundCode = matchDefMatch[1];

        // Extract the full Match template
        let matchContent = line;
        let braceDepth = 0;
        let j = i;

        // Count opening braces in current line
        for (const char of line) {
          if (char === '{') braceDepth++;
          else if (char === '}') braceDepth--;
        }

        // Continue reading lines until braces are balanced
        while (braceDepth > 0 && j < lines.length - 1) {
          j++;
          matchContent += '\n' + lines[j];
          for (const char of lines[j]) {
            if (char === '{') braceDepth++;
            else if (char === '}') braceDepth--;
          }
        }

        const match = this.parseMatchTemplate(matchContent);
        if (match.matchIds.length > 0) {
          bracketMatches.push({
            roundCode,
            roundName: currentRoundName,
            match,
          });
        }
      }
    }

    return bracketMatches;
  }

  /**
   * Parse standalone Match templates not in Matchlists
   */
  private parseStandaloneMatches(wikitext: string): ParsedMatch[] {
    const matches: ParsedMatch[] = [];

    // Find Match templates that contain matchid
    const matchRegex = /\{\{Match\n[^}]*matchid\d?=[^}]*\}\}/gs;
    let match;

    while ((match = matchRegex.exec(wikitext)) !== null) {
      const parsed = this.parseMatchTemplate(match[0]);
      if (parsed.matchIds.length > 0) {
        matches.push(parsed);
      }
    }

    return matches;
  }

  /**
   * Parse a single Match template to extract relevant data
   */
  private parseMatchTemplate(content: string): ParsedMatch {
    const matchIds: number[] = [];

    // Extract match IDs (matchid1, matchid2, matchid3)
    const matchIdRegex = /matchid(\d)?\s*=\s*(\d+)/gi;
    let idMatch;
    while ((idMatch = matchIdRegex.exec(content)) !== null) {
      const id = parseInt(idMatch[2], 10);
      if (!isNaN(id) && id > 0) {
        matchIds.push(id);
      }
    }

    // Extract bestof
    const bestOfMatch = content.match(/bestof\s*=\s*(\d+)/i);
    const bestOf = bestOfMatch ? parseInt(bestOfMatch[1], 10) : undefined;

    // Extract teams
    const team1Match = content.match(
      /opponent1=\{\{TeamOpponent\|([^|}]+)/i,
    );
    const team2Match = content.match(
      /opponent2=\{\{TeamOpponent\|([^|}]+)/i,
    );
    const team1 = team1Match ? team1Match[1].trim() : undefined;
    const team2 = team2Match ? team2Match[1].trim() : undefined;

    // Extract date
    const dateMatch = content.match(/date=([^|}\n]+)/i);
    const date = dateMatch ? dateMatch[1].trim() : undefined;

    return { matchIds, team1, team2, date, bestOf };
  }

  /**
   * Convert bestOf number to format string
   */
  private getBestOfFormat(
    bestOf: number,
  ): 'bo1' | 'bo2' | 'bo3' | 'bo5' {
    switch (bestOf) {
      case 1:
        return 'bo1';
      case 2:
        return 'bo2';
      case 3:
        return 'bo3';
      case 5:
        return 'bo5';
      default:
        return bestOf <= 2 ? 'bo2' : 'bo3';
    }
  }

  /**
   * Normalize playoff round name to enum value
   */
  private normalizePlayoffRound(roundName: string): PlayoffRound {
    const lower = roundName.toLowerCase();

    if (lower.includes('grand final')) return 'grand_final';
    if (lower.includes('placement') || lower.includes('3rd place'))
      return 'placement';
    if (lower.includes('tiebreaker')) return 'tiebreaker';

    if (lower.includes('upper') || lower.includes('winner')) {
      // Check quarter/semi before final since "quarterfinal" contains "final"
      if (lower.includes('quarter')) return 'upper_bracket_qf';
      if (lower.includes('semi')) return 'upper_bracket_sf';
      if (lower.includes('final')) return 'upper_bracket_final';
      if (lower.includes('round 1') || lower.includes('r1'))
        return 'upper_bracket_r1';
      return 'upper_bracket_qf'; // Default for upper bracket
    }

    if (lower.includes('lower') || lower.includes('loser')) {
      // Check quarter/semi before final since "quarterfinal" contains "final"
      if (lower.includes('quarter')) return 'lower_bracket_qf';
      if (lower.includes('semi')) return 'lower_bracket_sf';
      if (lower.includes('final')) return 'lower_bracket_final';
      if (lower.includes('round 3') || lower.includes('r3'))
        return 'lower_bracket_r3';
      if (lower.includes('round 2') || lower.includes('r2'))
        return 'lower_bracket_r2';
      if (lower.includes('round 1') || lower.includes('r1'))
        return 'lower_bracket_r1';
      return 'lower_bracket_r1'; // Default for lower bracket
    }

    return 'unknown';
  }

  /**
   * Convert round code (R2M1) to human-readable name
   */
  private roundCodeToName(roundCode: string): string {
    // Common TI bracket mappings (8U8L format)
    const mappings: Record<string, string> = {
      R1M1: 'Lower Bracket Round 1',
      R1M2: 'Lower Bracket Round 1',
      R1M3: 'Lower Bracket Round 1',
      R1M4: 'Lower Bracket Round 1',
      R2M1: 'Upper Bracket Quarterfinals',
      R2M2: 'Upper Bracket Quarterfinals',
      R2M3: 'Upper Bracket Quarterfinals',
      R2M4: 'Upper Bracket Quarterfinals',
      R2M5: 'Lower Bracket Round 2',
      R2M6: 'Lower Bracket Round 2',
      R2M7: 'Lower Bracket Round 2',
      R2M8: 'Lower Bracket Round 2',
      R3M1: 'Lower Bracket Round 3',
      R3M2: 'Lower Bracket Round 3',
      R4M1: 'Upper Bracket Semifinals',
      R4M2: 'Upper Bracket Semifinals',
      R4M3: 'Lower Bracket Quarterfinals',
      R4M4: 'Lower Bracket Quarterfinals',
      R5M1: 'Lower Bracket Semifinal',
      R6M1: 'Upper Bracket Final',
      R6M2: 'Lower Bracket Final',
      R7M1: 'Grand Final',
    };

    return mappings[roundCode] || `Round ${roundCode}`;
  }

  /**
   * Get stage info for a specific match ID
   */
  async getMatchStageInfo(
    tournamentPath: string,
    matchId: number,
  ): Promise<MatchStageInfo | null> {
    const mapping = await this.getTournamentStageMapping(tournamentPath);
    return mapping.matches.get(matchId) || null;
  }

  /**
   * Get all match IDs for a specific stage
   */
  async getMatchIdsByStage(
    tournamentPath: string,
    stage: TournamentStage,
  ): Promise<number[]> {
    const mapping = await this.getTournamentStageMapping(tournamentPath);
    const matchIds: number[] = [];

    for (const [matchId, info] of mapping.matches) {
      if (info.stage === stage) {
        matchIds.push(matchId);
      }
    }

    return matchIds;
  }

  /**
   * Get all match IDs for a specific playoff round
   */
  async getMatchIdsByRound(
    tournamentPath: string,
    round: PlayoffRound,
  ): Promise<number[]> {
    const mapping = await this.getTournamentStageMapping(tournamentPath);
    const matchIds: number[] = [];

    for (const [matchId, info] of mapping.matches) {
      if (info.round === round) {
        matchIds.push(matchId);
      }
    }

    return matchIds;
  }

  // ============ HTML Parsing Methods (LPDB fallback) ============

  /**
   * Parse group stage from rendered HTML (for LPDB-based tournaments like TI 2025)
   * Extracts match IDs from datdota.com/matches/ links organized by section headers
   */
  private parseGroupStageHtml(
    html: string,
    pageSource: string,
  ): SeriesStageInfo[] {
    const series: SeriesStageInfo[] = [];

    // Define possible section patterns for group stages
    // TI 2025 uses Round_1, Round_2, etc. + Elimination_Round
    // Other tournaments might use Group_A, Group_B, etc.
    const sectionPatterns = [
      // Swiss format (TI 2025)
      { id: 'Round_1', name: 'Round 1' },
      { id: 'Round_2', name: 'Round 2' },
      { id: 'Round_3', name: 'Round 3' },
      { id: 'Round_4', name: 'Round 4' },
      { id: 'Round_5', name: 'Round 5' },
      { id: 'Elimination_Round', name: 'Elimination Round' },
      // Traditional group format
      { id: 'Group_A', name: 'Group A' },
      { id: 'Group_B', name: 'Group B' },
      { id: 'Group_C', name: 'Group C' },
      { id: 'Group_D', name: 'Group D' },
    ];

    // Find positions of sections in HTML
    const foundSections: Array<{ name: string; id: string; position: number }> = [];
    for (const section of sectionPatterns) {
      const pattern = new RegExp(`id="${section.id}"`, 'i');
      const match = pattern.exec(html);
      if (match) {
        foundSections.push({
          name: section.name,
          id: section.id,
          position: match.index,
        });
      }
    }

    // Sort by position
    foundSections.sort((a, b) => a.position - b.position);

    if (foundSections.length === 0) {
      // No sections found, try to get all matches as one group
      const allMatchIds = this.extractMatchIdsFromHtml(html);
      if (allMatchIds.length > 0) {
        series.push({
          stage: 'group_stage',
          substage: 'Group Stage',
          pageSource,
          seriesFormat: 'bo2',
          matchIds: allMatchIds,
        });
      }
      return series;
    }

    // Extract matches between each section
    for (let i = 0; i < foundSections.length; i++) {
      const section = foundSections[i];
      const startPos = section.position;
      const endPos = i + 1 < foundSections.length
        ? foundSections[i + 1].position
        : html.length;

      const sectionHtml = html.substring(startPos, endPos);
      const matchIds = this.extractMatchIdsFromHtml(sectionHtml);

      if (matchIds.length > 0) {
        const isEliminationRound = section.name.toLowerCase().includes('elimination');
        series.push({
          stage: 'group_stage',
          substage: section.name,
          round: isEliminationRound ? 'tiebreaker' : undefined,
          pageSource,
          seriesFormat: this.guessSeriesFormat(matchIds.length),
          matchIds,
        });
      }
    }

    return series;
  }

  /**
   * Parse main event/playoffs from rendered HTML (for LPDB-based tournaments)
   */
  private parseMainEventHtml(
    html: string,
    pageSource: string,
  ): SeriesStageInfo[] {
    const series: SeriesStageInfo[] = [];

    // Define playoff section patterns
    const sectionPatterns = [
      { id: 'Upper_Bracket_Quarterfinals', name: 'Upper Bracket Quarterfinals', round: 'upper_bracket_qf' as PlayoffRound },
      { id: 'Upper_Bracket_Semifinals', name: 'Upper Bracket Semifinals', round: 'upper_bracket_sf' as PlayoffRound },
      { id: 'Upper_Bracket_Final', name: 'Upper Bracket Final', round: 'upper_bracket_final' as PlayoffRound },
      { id: 'Lower_Bracket_Round_1', name: 'Lower Bracket Round 1', round: 'lower_bracket_r1' as PlayoffRound },
      { id: 'Lower_Bracket_Round_2', name: 'Lower Bracket Round 2', round: 'lower_bracket_r2' as PlayoffRound },
      { id: 'Lower_Bracket_Quarterfinals', name: 'Lower Bracket Quarterfinals', round: 'lower_bracket_qf' as PlayoffRound },
      { id: 'Lower_Bracket_Semifinal', name: 'Lower Bracket Semifinal', round: 'lower_bracket_sf' as PlayoffRound },
      { id: 'Lower_Bracket_Final', name: 'Lower Bracket Final', round: 'lower_bracket_final' as PlayoffRound },
      { id: 'Grand_Final', name: 'Grand Final', round: 'grand_final' as PlayoffRound },
    ];

    // Find positions of sections
    const foundSections: Array<{ name: string; id: string; position: number; round: PlayoffRound }> = [];
    for (const section of sectionPatterns) {
      const pattern = new RegExp(`id="${section.id}"`, 'i');
      const match = pattern.exec(html);
      if (match) {
        foundSections.push({
          name: section.name,
          id: section.id,
          position: match.index,
          round: section.round,
        });
      }
    }

    foundSections.sort((a, b) => a.position - b.position);

    if (foundSections.length === 0) {
      // No specific sections found, get all matches as playoffs
      const allMatchIds = this.extractMatchIdsFromHtml(html);
      if (allMatchIds.length > 0) {
        series.push({
          stage: 'playoffs',
          substage: 'Playoffs',
          round: 'unknown',
          pageSource,
          seriesFormat: 'bo3',
          matchIds: allMatchIds,
        });
      }
      return series;
    }

    // Extract matches between sections
    for (let i = 0; i < foundSections.length; i++) {
      const section = foundSections[i];
      const startPos = section.position;
      const endPos = i + 1 < foundSections.length
        ? foundSections[i + 1].position
        : html.length;

      const sectionHtml = html.substring(startPos, endPos);
      const matchIds = this.extractMatchIdsFromHtml(sectionHtml);

      if (matchIds.length > 0) {
        series.push({
          stage: 'playoffs',
          substage: section.name,
          round: section.round,
          pageSource,
          seriesFormat: this.guessSeriesFormat(matchIds.length),
          matchIds,
        });
      }
    }

    return series;
  }

  /**
   * Extract unique match IDs from HTML content
   * Looks for datdota.com/matches/ links which contain Dota match IDs
   */
  private extractMatchIdsFromHtml(html: string): number[] {
    const matchIdPattern = /datdota\.com\/matches\/(\d+)/g;
    const matchIds = new Set<number>();

    let match;
    while ((match = matchIdPattern.exec(html)) !== null) {
      const id = parseInt(match[1], 10);
      if (!isNaN(id) && id > 0) {
        matchIds.add(id);
      }
    }

    return Array.from(matchIds);
  }

  /**
   * Guess series format based on number of matches
   */
  private guessSeriesFormat(matchCount: number): 'bo1' | 'bo2' | 'bo3' | 'bo5' {
    // This is a rough guess - individual series would need more context
    if (matchCount <= 5) return 'bo2'; // Likely group stage bo2
    if (matchCount <= 15) return 'bo3'; // Likely early playoffs
    return 'bo3'; // Default
  }
}
