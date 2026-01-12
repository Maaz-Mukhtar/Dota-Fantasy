import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import {
  LiquipediaApiResponse,
  TournamentInfo,
  ParsedInfobox,
  TournamentTeam,
} from './liquipedia.types';

@Injectable()
export class LiquipediaService {
  private readonly logger = new Logger(LiquipediaService.name);
  private readonly baseUrl = 'https://liquipedia.net/dota2/api.php';
  private readonly userAgent: string;

  // Rate limiting
  private lastStandardRequest = 0;
  private lastParseRequest = 0;
  private readonly STANDARD_RATE_LIMIT = 2000; // 2 seconds
  private readonly PARSE_RATE_LIMIT = 30000; // 30 seconds

  // Simple in-memory cache
  private cache = new Map<string, { data: unknown; timestamp: number }>();
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.userAgent = 'DotaFantasyApp/1.0 (https://github.com/Maaz-Mukhtar/Dota-Fantasy; contact@dotafantasy.app)';
  }

  /**
   * Rate limit helper - waits if needed before making request
   */
  private async waitForRateLimit(isParse: boolean): Promise<void> {
    const now = Date.now();
    const lastRequest = isParse ? this.lastParseRequest : this.lastStandardRequest;
    const rateLimit = isParse ? this.PARSE_RATE_LIMIT : this.STANDARD_RATE_LIMIT;
    const waitTime = lastRequest + rateLimit - now;

    if (waitTime > 0) {
      this.logger.debug(`Rate limiting: waiting ${waitTime}ms`);
      await new Promise((resolve) => setTimeout(resolve, waitTime));
    }

    if (isParse) {
      this.lastParseRequest = Date.now();
    } else {
      this.lastStandardRequest = Date.now();
    }
  }

  /**
   * Check cache for existing data
   */
  private getFromCache<T>(key: string): T | null {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
      this.logger.debug(`Cache hit for: ${key}`);
      return cached.data as T;
    }
    return null;
  }

  /**
   * Store data in cache
   */
  private setCache(key: string, data: unknown): void {
    this.cache.set(key, { data, timestamp: Date.now() });
  }

  /**
   * Make a request to the Liquipedia MediaWiki API
   */
  private async makeRequest(
    params: Record<string, string>,
    isParse = false,
  ): Promise<LiquipediaApiResponse> {
    const cacheKey = JSON.stringify(params);
    const cached = this.getFromCache<LiquipediaApiResponse>(cacheKey);
    if (cached) return cached;

    await this.waitForRateLimit(isParse);

    const url = new URL(this.baseUrl);
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.append(key, value);
    });

    this.logger.debug(`Making request to: ${url.toString()}`);

    try {
      const response = await firstValueFrom(
        this.httpService.get<LiquipediaApiResponse>(url.toString(), {
          headers: {
            'User-Agent': this.userAgent,
            'Accept-Encoding': 'gzip',
            Accept: 'application/json',
          },
        }),
      );

      if (response.data.error) {
        throw new Error(
          `Liquipedia API error: ${response.data.error.code} - ${response.data.error.info}`,
        );
      }

      this.setCache(cacheKey, response.data);
      return response.data;
    } catch (error) {
      this.logger.error(`Liquipedia API request failed: ${error}`);
      throw error;
    }
  }

  /**
   * Get raw wikitext content for a page
   */
  async getPageWikitext(pageName: string): Promise<string> {
    const response = await this.makeRequest(
      {
        action: 'query',
        titles: pageName,
        prop: 'revisions',
        rvprop: 'content',
        format: 'json',
      },
      false,
    );

    const pages = response.query?.pages;
    if (!pages) return '';

    const page = Object.values(pages)[0];
    return page?.revisions?.[0]?.['*'] || '';
  }

  /**
   * Parse a page and get rendered HTML
   */
  async parsePage(pageName: string): Promise<string> {
    const response = await this.makeRequest(
      {
        action: 'parse',
        page: pageName,
        format: 'json',
      },
      true, // Parse action has stricter rate limits
    );

    return response.parse?.text?.['*'] || '';
  }

  /**
   * Parse wiki template/infobox from wikitext
   */
  parseInfobox(wikitext: string, templateName: string): ParsedInfobox {
    const result: ParsedInfobox = {};

    // Find the template - look for {{Infobox league with proper bracket matching
    const templateStart = wikitext.indexOf(`{{${templateName}`);
    if (templateStart === -1) return result;

    // Find the matching closing brackets
    let depth = 0;
    let templateEnd = templateStart;
    for (let i = templateStart; i < wikitext.length - 1; i++) {
      if (wikitext[i] === '{' && wikitext[i + 1] === '{') {
        depth++;
        i++; // Skip the second brace
      } else if (wikitext[i] === '}' && wikitext[i + 1] === '}') {
        depth--;
        i++; // Skip the second brace
        if (depth === 0) {
          templateEnd = i + 1;
          break;
        }
      }
    }

    const templateContent = wikitext.substring(templateStart, templateEnd);

    // Parse key-value pairs - handle both |key=value and | key = value formats
    // Split by lines first to handle multi-line values
    const lines = templateContent.split('\n');
    let currentKey: string | null = null;
    let currentValue = '';

    for (const line of lines) {
      // Check for new key-value pair
      const kvMatch = line.match(/^\s*\|([^=]+)=(.*)$/);
      if (kvMatch) {
        // Save previous key-value if exists
        if (currentKey) {
          result[currentKey] = this.cleanWikiMarkup(currentValue.trim());
        }
        currentKey = kvMatch[1].trim().toLowerCase().replace(/\s+/g, '_');
        currentValue = kvMatch[2];
      } else if (currentKey) {
        // Append to current value (multi-line value)
        currentValue += ' ' + line.trim();
      }
    }

    // Save the last key-value pair
    if (currentKey) {
      result[currentKey] = this.cleanWikiMarkup(currentValue.trim());
    }

    return result;
  }

  /**
   * Clean wiki markup from a value
   */
  private cleanWikiMarkup(value: string): string {
    if (!value) return '';

    return value
      // Handle [[Link|Text]] - keep Text
      .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, '$2')
      // Handle [[Link]] - keep Link
      .replace(/\[\[([^\]]+)\]\]/g, '$1')
      // Handle {{BASEPAGENAME}}
      .replace(/\{\{BASEPAGENAME\}\}/g, '')
      // Handle {{!}} (escaped pipe)
      .replace(/\{\{!\}\}/g, '|')
      // Handle {{Abbr/XX}} abbreviations
      .replace(/\{\{Abbr\/([^}]+)\}\}/g, '$1')
      // Remove nested templates but preserve simple ones
      .replace(/\{\{:[^}]+\}\}/g, '') // Remove transcluded pages
      .replace(/\{\{[^}]+\}\}/g, '')
      // Remove HTML tags but keep content
      .replace(/<br\s*\/?>/gi, ' ')
      .replace(/<[^>]+>/g, '')
      // Remove bold/italic markers
      .replace(/'''?/g, '')
      // Clean up whitespace
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Get tournament information
   */
  async getTournament(pageName: string): Promise<TournamentInfo> {
    this.logger.log(`Fetching tournament: ${pageName}`);

    const wikitext = await this.getPageWikitext(pageName);

    // Parse the Infobox league template
    const infobox = this.parseInfobox(wikitext, 'Infobox league');

    this.logger.debug(`Parsed infobox fields: ${Object.keys(infobox).join(', ')}`);

    // Parse team placements if available
    const teams = this.parseTeamPlacements(wikitext);

    // Build location from city and country
    const location = [infobox['city'], infobox['country']]
      .filter(Boolean)
      .join(', ');

    // Build venue from multiple venue fields
    const venues = [infobox['venue'], infobox['venue1'], infobox['venue2']]
      .filter(Boolean)
      .join('; ');

    // Build organizers list
    const organizers = [infobox['organizer'], infobox['organizer2']]
      .filter(Boolean)
      .join(', ');

    return {
      name: infobox['name'] || pageName.replace(/_/g, ' '),
      pageName,
      tier: infobox['liquipediatier'],
      type: infobox['type'],
      organizer: organizers || undefined,
      sponsor: infobox['sponsor'],
      series: infobox['series'],
      location: location || undefined,
      venue: venues || undefined,
      format: infobox['format'],
      prizePool: infobox['prizepool'] || infobox['prizepoolusd'],
      prizePoolUsd: undefined, // Will need separate API call or parsing
      startDate: infobox['sdate'] || infobox['date'],
      endDate: infobox['edate'],
      liquipediaUrl: `https://liquipedia.net/dota2/${encodeURIComponent(pageName)}`,
      teams,
      participants: infobox['team_number']
        ? parseInt(infobox['team_number'], 10)
        : undefined,
      winner: infobox['winner'] || infobox['1st'],
      runnerUp: infobox['runnerup'] || infobox['2nd'],
    };
  }

  /**
   * Parse team placements from wikitext
   */
  private parseTeamPlacements(wikitext: string): TournamentTeam[] {
    const teams: TournamentTeam[] = [];

    // Look for prize pool entries - common pattern in tournament pages
    const prizePoolRegex = /\{\{prize pool slot\|place=(\d+)[^}]*\|([^|}]+)/gi;
    let match;

    while ((match = prizePoolRegex.exec(wikitext)) !== null) {
      const placement = match[1];
      let teamName = match[2].trim();

      // Clean up team name
      teamName = teamName.replace(/\[\[([^\]|]+)\|?([^\]]*)\]\]/g, (_, link, text) =>
        text || link,
      );

      if (teamName) {
        teams.push({
          name: teamName,
          placement: `${placement}${this.getOrdinalSuffix(parseInt(placement))}`,
        });
      }
    }

    return teams;
  }

  /**
   * Get ordinal suffix for a number
   */
  private getOrdinalSuffix(n: number): string {
    const s = ['th', 'st', 'nd', 'rd'];
    const v = n % 100;
    return s[(v - 20) % 10] || s[v] || s[0];
  }

  /**
   * Get list of pages in a category
   */
  async getCategoryMembers(category: string, limit = 50): Promise<string[]> {
    const response = await this.makeRequest(
      {
        action: 'query',
        list: 'categorymembers',
        cmtitle: `Category:${category}`,
        cmlimit: limit.toString(),
        format: 'json',
      },
      false,
    );

    return (
      response.query?.categorymembers?.map((member) => member.title) || []
    );
  }

  /**
   * Search for tournaments by year
   */
  async searchTournaments(year: number): Promise<string[]> {
    // Get tournaments from the year category
    const categoryName = `Tournaments in ${year}`;
    return this.getCategoryMembers(categoryName);
  }

  /**
   * Get The International tournament data
   */
  async getTheInternational(year: number): Promise<TournamentInfo> {
    // The International page naming convention
    const pageName = `The_International/${year}`;
    return this.getTournament(pageName);
  }

  /**
   * Get multiple TI tournaments
   */
  async getMultipleTIs(years: number[]): Promise<TournamentInfo[]> {
    const results: TournamentInfo[] = [];

    for (const year of years) {
      try {
        this.logger.log(`Fetching TI ${year}...`);
        const ti = await this.getTheInternational(year);
        results.push(ti);
      } catch (error) {
        this.logger.error(`Failed to fetch TI ${year}: ${error}`);
      }
    }

    return results;
  }
}
