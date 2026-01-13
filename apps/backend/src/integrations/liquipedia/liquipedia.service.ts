import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import {
  LiquipediaApiResponse,
  TournamentInfo,
  ParsedInfobox,
  TournamentTeam,
  TournamentParticipant,
  ParticipantPlayer,
  PrizeSlot,
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
   * @param preserveTemplates - keys for which to preserve raw template syntax
   */
  parseInfobox(wikitext: string, templateName: string, preserveTemplates: string[] = []): ParsedInfobox {
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
          // Preserve raw value for specific keys, clean others
          if (preserveTemplates.includes(currentKey)) {
            result[currentKey] = currentValue.trim();
          } else {
            result[currentKey] = this.cleanWikiMarkup(currentValue.trim());
          }
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
      if (preserveTemplates.includes(currentKey)) {
        result[currentKey] = currentValue.trim();
      } else {
        result[currentKey] = this.cleanWikiMarkup(currentValue.trim());
      }
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
   * Parse TeamCard templates to extract full roster info
   */
  parseTeamCards(wikitext: string): TournamentParticipant[] {
    const participants: TournamentParticipant[] = [];

    // Find all TeamCard templates
    const teamCardRegex = /\{\{TeamCard\s*\n([^}]*(?:\{\{[^}]*\}\}[^}]*)*)\}\}/gi;
    let match;

    while ((match = teamCardRegex.exec(wikitext)) !== null) {
      const cardContent = match[1];
      const participant = this.parseTeamCardContent(cardContent);
      if (participant) {
        participants.push(participant);
      }
    }

    return participants;
  }

  /**
   * Parse individual TeamCard content
   */
  private parseTeamCardContent(content: string): TournamentParticipant | null {
    const lines = content.split('\n');
    const data: Record<string, string> = {};

    for (const line of lines) {
      const kvMatch = line.match(/^\s*\|([^=]+)=(.*)$/);
      if (kvMatch) {
        const key = kvMatch[1].trim().toLowerCase();
        let value = kvMatch[2].trim();
        // Remove any additional pipe parameters within the value
        // BUT preserve pipes inside [[ ]] wiki links
        if (value.includes('|') && !value.includes('[[')) {
          value = value.split('|')[0].trim();
        }
        data[key] = value;
      }
    }

    if (!data['team']) return null;

    // Extract players (p1-p5)
    const players: ParticipantPlayer[] = [];
    for (let i = 1; i <= 5; i++) {
      const playerKey = `p${i}`;
      if (data[playerKey]) {
        let nickname = data[playerKey];
        // Clean up player name - remove trailing wiki params
        nickname = nickname.split('|')[0].trim();
        const player: ParticipantPlayer = {
          nickname: this.cleanWikiMarkup(nickname),
          position: i,
        };
        // Check for country flag
        if (data[`${playerKey}flag`]) {
          player.country = data[`${playerKey}flag`];
        }
        players.push(player);
      }
    }

    // Check for substitutes (s1, s2, etc.)
    for (let i = 1; i <= 3; i++) {
      const subKey = `s${i}`;
      if (data[subKey]) {
        let nickname = data[subKey];
        nickname = nickname.split('|')[0].trim();
        const player: ParticipantPlayer = {
          nickname: this.cleanWikiMarkup(nickname),
          isSubstitute: true,
        };
        if (data[`${subKey}flag`]) {
          player.country = data[`${subKey}flag`];
        }
        players.push(player);
      }
    }

    // Clean coach name
    let coach = data['c'];
    if (coach) {
      coach = coach.split('|')[0].trim();
      coach = this.cleanWikiMarkup(coach);
    }

    // Clean qualifier - extract region name from links like [[/Western Europe|Western Europe]]
    let qualifier = data['qualifier'];
    if (qualifier) {
      // Handle [[/Region|Text]] format
      const regionMatch = qualifier.match(/\[\[\/([^\]|]+)\|?([^\]]*)\]\]/);
      if (regionMatch) {
        qualifier = regionMatch[2] || regionMatch[1];
      }
      // Handle [[/Region]] format (no pipe)
      else if (qualifier.startsWith('[[/')) {
        qualifier = qualifier.replace(/\[\[\/([^\]]+)\]\]/, '$1');
      }
      qualifier = this.cleanWikiMarkup(qualifier);
    }

    // Clean notes - remove wiki references
    let notes = data['inotes'];
    if (notes) {
      notes = notes.replace(/\{\{cite web[^}]*\}\}/gi, '');
      notes = notes.replace(/\{\{Player[^}]*\}\}/gi, '');
      notes = notes.replace(/<ref[^>]*>.*?<\/ref>/gi, '');
      notes = notes.replace(/<ref[^/]*\/>/gi, '');
      notes = this.cleanWikiMarkup(notes).trim();
    }

    return {
      teamName: this.cleanWikiMarkup(data['team']),
      players,
      coach: coach || undefined,
      qualifier: qualifier || undefined,
      placement: data['placement'] || undefined,
      notes: notes || undefined,
    };
  }

  /**
   * Parse prize pool distribution
   */
  parsePrizeDistribution(wikitext: string): PrizeSlot[] {
    const slots: PrizeSlot[] = [];

    // Match {{Slot|place=X|usdprize=Y|freetext=Z%|...}} patterns
    // The usdprize often contains complex expressions like {{formatnum:{{#expr:...}}}}
    const slotRegex = /\{\{Slot\|place=([^|]+)\|usdprize=([^|]*\}\}[^|]*|\S+)(?:\|freetext=([^|}]+))?/gi;
    let match;

    while ((match = slotRegex.exec(wikitext)) !== null) {
      const place = match[1].trim();
      const percentage = match[3]?.trim();

      slots.push({
        place,
        percentage: percentage || undefined,
      });
    }

    return slots;
  }

  /**
   * Parse prize pool with known total to calculate actual amounts
   */
  parsePrizeDistributionWithTotal(wikitext: string, totalPrizePool: number): PrizeSlot[] {
    const slots = this.parsePrizeDistribution(wikitext);

    // Calculate actual amounts from percentages
    for (const slot of slots) {
      if (slot.percentage) {
        const percentMatch = slot.percentage.match(/(\d+\.?\d*)%?/);
        if (percentMatch) {
          const percent = parseFloat(percentMatch[1]);
          slot.usdPrize = Math.round(totalPrizePool * (percent / 100));
        }
      }
    }

    return slots;
  }

  /**
   * Get comprehensive tournament data including all participants and prize pool
   */
  async getTournamentFull(pageName: string): Promise<TournamentInfo> {
    this.logger.log(`Fetching full tournament data: ${pageName}`);

    const wikitext = await this.getPageWikitext(pageName);

    // Parse the Infobox league template - preserve prizepoolusd for template lookup
    const infobox = this.parseInfobox(wikitext, 'Infobox league', ['prizepoolusd']);

    this.logger.debug(`Parsed infobox fields: ${Object.keys(infobox).join(', ')}`);
    this.logger.debug(`Prize pool raw: ${infobox['prizepoolusd']}`);

    // Parse all TeamCards
    const allParticipants = this.parseTeamCards(wikitext);

    // Separate direct invites from qualified teams
    const directInvites = allParticipants.filter(
      p => p.qualifier?.toLowerCase() === 'invited' ||
           p.qualifier?.toLowerCase().includes('replacement')
    );
    const qualifiedTeams = allParticipants.filter(
      p => p.qualifier &&
           p.qualifier.toLowerCase() !== 'invited' &&
           !p.qualifier.toLowerCase().includes('replacement')
    );

    // Parse prize pool distribution (will be updated with amounts after we get total)
    let prizeDistribution = this.parsePrizeDistribution(wikitext);

    // Try to fetch actual prize pool value if it's a template reference
    let prizePoolUsd: number | undefined;
    const prizePoolTemplate = infobox['prizepoolusd'];
    if (prizePoolTemplate?.includes(':')) {
      // It's a template reference like {{:The_International/2025/prizepool}}
      const prizePageMatch = prizePoolTemplate.match(/\{\{:([^}]+)\}\}/);
      if (prizePageMatch) {
        try {
          const prizeWikitext = await this.getPageWikitext(prizePageMatch[1]);
          prizePoolUsd = parseFloat(prizeWikitext.replace(/,/g, ''));
        } catch (e) {
          this.logger.warn(`Failed to fetch prize pool: ${e}`);
        }
      }
    } else if (prizePoolTemplate) {
      prizePoolUsd = parseFloat(prizePoolTemplate.replace(/[,$]/g, ''));
    }

    // If we have the total prize pool, calculate distribution amounts
    if (prizePoolUsd && prizeDistribution.length > 0) {
      prizeDistribution = this.parsePrizeDistributionWithTotal(wikitext, prizePoolUsd);
    }

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
      shortName: infobox['shortname'],
      tickerName: infobox['tickername'],
      pageName,
      tier: infobox['liquipediatier'],
      valveTier: infobox['publishertier'],
      type: infobox['type'],
      organizer: organizers || undefined,
      sponsor: infobox['sponsor'],
      series: infobox['series'],
      location: location || undefined,
      venue: venues || undefined,
      format: infobox['format'],
      prizePool: infobox['prizepool'] || infobox['prizepoolusd'],
      prizePoolUsd,
      startDate: infobox['sdate'] || infobox['date'],
      endDate: infobox['edate'],
      patch: infobox['patch'],
      leagueId: infobox['leagueid'],
      liquipediaUrl: `https://liquipedia.net/dota2/${encodeURIComponent(pageName)}`,
      teams: this.parseTeamPlacements(wikitext),
      participants: infobox['team_number']
        ? parseInt(infobox['team_number'], 10)
        : undefined,
      winner: infobox['winner'] || infobox['1st'],
      runnerUp: infobox['runnerup'] || infobox['2nd'],
      directInvites,
      qualifiedTeams,
      prizeDistribution,
    };
  }

  /**
   * Get comprehensive tournament data WITH team logos
   * Note: This is slower due to fetching logos for each team (rate limited)
   */
  async getTournamentFullWithLogos(pageName: string): Promise<TournamentInfo> {
    // First get the basic tournament data
    const tournament = await this.getTournamentFull(pageName);

    // Collect all team names
    const allTeams = [
      ...(tournament.directInvites || []),
      ...(tournament.qualifiedTeams || []),
    ];

    this.logger.log(`Fetching logos for ${allTeams.length} teams...`);

    // Fetch logos for each team
    for (const team of allTeams) {
      let logos = await this.getTeamLogo(team.teamName);

      // If no logo found and team has notes about playing under different name,
      // try to extract the original team name and fetch that logo
      if (!logos.logoUrl && team.notes) {
        const originalTeamMatch = team.notes.match(/^\[\[([^\]]+)\]\] competed under/i) ||
                                   team.notes.match(/^([A-Za-z0-9\s]+) competed under/i);
        if (originalTeamMatch) {
          const originalTeamName = originalTeamMatch[1].trim();
          this.logger.debug(`Trying original team name: ${originalTeamName}`);
          logos = await this.getTeamLogo(originalTeamName);
        }
      }

      team.logoUrl = logos.logoUrl;
      team.logoDarkUrl = logos.logoDarkUrl;
    }

    return tournament;
  }

  /**
   * Get image URL from Liquipedia using imageinfo API
   */
  async getImageUrl(imageName: string): Promise<string | null> {
    if (!imageName) return null;

    try {
      const response = await this.makeRequest(
        {
          action: 'query',
          titles: `File:${imageName}`,
          prop: 'imageinfo',
          iiprop: 'url',
          format: 'json',
        },
        false,
      );

      const pages = response.query?.pages;
      if (!pages) return null;

      const page = Object.values(pages)[0] as any;
      return page?.imageinfo?.[0]?.url || null;
    } catch (error) {
      this.logger.warn(`Failed to get image URL for ${imageName}: ${error}`);
      return null;
    }
  }

  /**
   * Get team logo URL by fetching team page and extracting image
   * Handles redirects automatically
   */
  async getTeamLogo(teamName: string): Promise<{ logoUrl?: string; logoDarkUrl?: string }> {
    try {
      // Convert team name to page name (replace spaces with underscores)
      const pageName = teamName.replace(/\s+/g, '_');

      // Fetch with redirect handling
      const response = await this.makeRequest(
        {
          action: 'query',
          titles: pageName,
          prop: 'revisions',
          rvprop: 'content',
          redirects: '1', // Follow redirects
          format: 'json',
        },
        false,
      );

      const pages = response.query?.pages;
      if (!pages) return {};

      const page = Object.values(pages)[0] as any;
      const wikitext = page?.revisions?.[0]?.['*'] || '';

      if (!wikitext) return {};

      // Parse the team infobox
      const infobox = this.parseInfobox(wikitext, 'Infobox team');

      const imageName = infobox['image'];
      const imageDarkName = infobox['imagedark'];

      let logoUrl: string | undefined;
      let logoDarkUrl: string | undefined;

      if (imageName) {
        const url = await this.getImageUrl(imageName);
        if (url) logoUrl = url;
      }

      if (imageDarkName) {
        const url = await this.getImageUrl(imageDarkName);
        if (url) logoDarkUrl = url;
      }

      return { logoUrl, logoDarkUrl };
    } catch (error) {
      this.logger.warn(`Failed to get team logo for ${teamName}: ${error}`);
      return {};
    }
  }

  /**
   * Get team logos for multiple teams (with rate limiting)
   */
  async getTeamLogos(teamNames: string[]): Promise<Map<string, { logoUrl?: string; logoDarkUrl?: string }>> {
    const logos = new Map<string, { logoUrl?: string; logoDarkUrl?: string }>();

    for (const teamName of teamNames) {
      this.logger.debug(`Fetching logo for: ${teamName}`);
      const logo = await this.getTeamLogo(teamName);
      logos.set(teamName, logo);
    }

    return logos;
  }

  /**
   * Get all images used on a page
   */
  async getPageImages(pageName: string): Promise<string[]> {
    try {
      const response = await this.makeRequest(
        {
          action: 'parse',
          page: pageName,
          prop: 'images',
          format: 'json',
        },
        true, // Parse action has stricter rate limits
      );

      return (response.parse as any)?.images || [];
    } catch (error) {
      this.logger.warn(`Failed to get images for page ${pageName}: ${error}`);
      return [];
    }
  }

  /**
   * Get tournament logo URL from Liquipedia
   * Looks for images with patterns like:
   * - Tournament_Name_padded_allmode.png (for TI)
   * - Tournament_Name_lightmode.png / Tournament_Name_darkmode.png
   * - Tournament_Name_allmode.png
   * - Tournament_Name.png (simple format)
   */
  async getTournamentLogo(pageName: string): Promise<{ logoUrl?: string; logoDarkUrl?: string }> {
    try {
      const images = await this.getPageImages(pageName);

      if (!images.length) {
        this.logger.debug(`No images found for tournament: ${pageName}`);
        return {};
      }

      this.logger.debug(`Found ${images.length} images for ${pageName}`);

      // Build tournament name pattern from page name
      // e.g., "The_International/2025" -> "The_International_2025"
      const tournamentNamePattern = pageName.replace(/\//g, '_');

      // Known team name patterns to exclude
      const teamPatterns = [
        /^team_/i,
        /_team_/i,
        /^aurora_gaming/i,
        /^betboom_team/i,
        /^heroic/i,
        /^nigma/i,
        /^tundra/i,
        /^xtreme_gaming/i,
        /^parivision/i,
        /^gaimin/i,
        /^falcons/i,
        /_esports_/i,
        /_gaming_/i,
        /^og_/i,
        /^eg_/i,
        /^liquid_/i,
        /^secret_/i,
        /^spirit_/i,
        /_Brothers_/i,
        /^Yakutou/i,
        /^g2\./i,
        /^cloud9/i,
        /^nouns/i,
        /^1win/i,
        /^talon/i,
        /^beastcoast/i,
        /^gladiators/i,
      ];

      // Filter out non-tournament images
      const isTeamLogo = (img: string) => teamPatterns.some(p => p.test(img));
      const isUtilityImage = (img: string) => {
        const lower = img.toLowerCase();
        return lower.includes('_hd.png') ||
               lower.includes('icon_dota2') ||
               lower.includes('gold.png') ||
               lower.includes('silver.png') ||
               lower.includes('bronze.png') ||
               lower.includes('copper.png') ||
               lower.includes('vod-') ||
               lower.includes('valve_logo') ||
               lower.includes('aegis_') ||
               lower.endsWith('_win_') ||
               lower.includes('_win_the_');
      };

      // Find exact tournament name match first (highest priority)
      // e.g., "The_International_2025.png"
      const exactMatch = images.find(img =>
        img.toLowerCase() === `${tournamentNamePattern.toLowerCase()}.png`
      );

      if (exactMatch) {
        const url = await this.getImageUrl(exactMatch);
        if (url) {
          this.logger.debug(`Found exact match logo: ${exactMatch}`);
          return { logoUrl: url };
        }
      }

      // Extract series name (e.g., "DreamLeague" from "DreamLeague/Season_22")
      const seriesName = pageName.split('/')[0];
      const escapeRegex = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

      // Priority patterns to search for tournament logos
      const lightPatterns = [
        // Exact tournament name match
        new RegExp(`^${escapeRegex(tournamentNamePattern)}_padded_allmode\\.png$`, 'i'),
        new RegExp(`^${escapeRegex(tournamentNamePattern)}_allmode\\.png$`, 'i'),
        new RegExp(`^${escapeRegex(tournamentNamePattern)}_lightmode\\.png$`, 'i'),
        // Series name match (e.g., DreamLeague_2023_lightmode.png)
        new RegExp(`^${escapeRegex(seriesName)}_\\d{4}_lightmode\\.png$`, 'i'),
        new RegExp(`^${escapeRegex(seriesName)}_\\d{4}_allmode\\.png$`, 'i'),
        // General series name match
        new RegExp(`^${escapeRegex(seriesName)}.*_lightmode\\.png$`, 'i'),
        new RegExp(`^${escapeRegex(seriesName)}.*_padded_allmode\\.png$`, 'i'),
      ];

      // Dark patterns - only match tournament-specific dark logos
      const darkPatterns = [
        new RegExp(`^${escapeRegex(tournamentNamePattern)}_darkmode\\.png$`, 'i'),
        new RegExp(`^${escapeRegex(seriesName)}_\\d{4}_darkmode\\.png$`, 'i'),
        new RegExp(`^${escapeRegex(seriesName)}.*_darkmode\\.png$`, 'i'),
      ];

      // Filter tournament images (exclude teams and utility images)
      const tournamentImages = images.filter(img =>
        !isTeamLogo(img) && !isUtilityImage(img) && img.endsWith('.png')
      );

      this.logger.debug(`Filtered tournament images: ${tournamentImages.slice(0, 8).join(', ')}`);

      let lightLogo: string | undefined;
      let darkLogo: string | undefined;

      // Find light mode logo
      for (const pattern of lightPatterns) {
        const match = tournamentImages.find(img => pattern.test(img));
        if (match) {
          const url = await this.getImageUrl(match);
          if (url) {
            lightLogo = url;
            this.logger.debug(`Found light logo: ${match}`);
            break;
          }
        }
      }

      // Find dark mode logo
      for (const pattern of darkPatterns) {
        const match = tournamentImages.find(img => pattern.test(img));
        if (match) {
          const url = await this.getImageUrl(match);
          if (url) {
            darkLogo = url;
            this.logger.debug(`Found dark logo: ${match}`);
            break;
          }
        }
      }

      return { logoUrl: lightLogo, logoDarkUrl: darkLogo };
    } catch (error) {
      this.logger.warn(`Failed to get tournament logo for ${pageName}: ${error}`);
      return {};
    }
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
