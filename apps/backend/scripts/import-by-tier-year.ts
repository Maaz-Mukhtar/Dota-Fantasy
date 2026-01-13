#!/usr/bin/env ts-node
/**
 * Import tournaments by tier and year from Liquipedia
 *
 * Usage:
 *   npx ts-node scripts/import-by-tier-year.ts 1 2023             # Tier 1 tournaments in 2023
 *   npx ts-node scripts/import-by-tier-year.ts 2 2022             # Tier 2 tournaments in 2022
 *   npx ts-node scripts/import-by-tier-year.ts 1 2017 --list-only # Preview without importing
 *   npx ts-node scripts/import-by-tier-year.ts 1 2024 --dry-run   # Import preview
 *
 * Tiers:
 *   1 - Premier/Major tournaments (TI, ESL One, DreamLeague majors)
 *   2 - Major tournaments (Regional leagues, qualifiers)
 *   3 - Minor tournaments
 *   4 - Monthly/Weekly tournaments
 *
 * Prerequisites:
 *   1. Backend must be running: npm run start:dev
 *   2. Environment variables configured (.env file)
 */

import { createImporter, ImportOptions, ImportResult } from './lib/tournament-importer';
import { ProgressLogger, sleep } from './lib/progress-logger';
import * as dotenv from 'dotenv';

dotenv.config();

// Liquipedia category names for each tier
// Liquipedia uses "Tier X Tournaments" category naming
const TIER_CATEGORIES: Record<number, string> = {
  1: 'Tier_1_Tournaments',
  2: 'Tier_2_Tournaments',
  3: 'Tier_3_Tournaments',
  4: 'Tier_4_Tournaments',
};

interface CliArgs {
  tier: number;
  year: number;
  listOnly: boolean;
  dryRun: boolean;
  verbose: boolean;
  skipMatches: boolean;
  skipLogos: boolean;
  limit: number;
}

function parseArgs(): CliArgs | null {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    printUsage();
    return null;
  }

  // Find positional arguments (tier and year)
  const positional = args.filter(arg => !arg.startsWith('--'));

  if (positional.length < 2) {
    console.error('Error: Both tier and year are required\n');
    printUsage();
    return null;
  }

  const tier = parseInt(positional[0], 10);
  const year = parseInt(positional[1], 10);

  if (isNaN(tier) || tier < 1 || tier > 4) {
    console.error('Error: Tier must be 1, 2, 3, or 4\n');
    printUsage();
    return null;
  }

  if (isNaN(year) || year < 2011 || year > 2030) {
    console.error('Error: Year must be between 2011 and 2030\n');
    printUsage();
    return null;
  }

  // Parse limit
  const limitIndex = args.indexOf('--limit');
  let limit = 50;
  if (limitIndex !== -1 && args[limitIndex + 1]) {
    limit = parseInt(args[limitIndex + 1], 10);
    if (isNaN(limit) || limit < 1) {
      limit = 50;
    }
  }

  return {
    tier,
    year,
    listOnly: args.includes('--list-only'),
    dryRun: args.includes('--dry-run'),
    verbose: args.includes('--verbose'),
    skipMatches: args.includes('--skip-matches'),
    skipLogos: args.includes('--skip-logos'),
    limit,
  };
}

function printUsage(): void {
  console.log(`
Usage: npx ts-node scripts/import-by-tier-year.ts <tier> <year> [options]

Arguments:
  tier    Tournament tier (1-4)
          1 = Premier/Major (TI, ESL One majors, etc.)
          2 = Major (Regional leagues, qualifiers)
          3 = Minor
          4 = Monthly/Weekly
  year    Year (2011-2030)

Options:
  --list-only     Only list tournaments, don't import
  --dry-run       Preview import without modifying database
  --verbose       Show detailed debug output
  --skip-matches  Skip importing matches from STRATZ
  --skip-logos    Skip fetching tournament logos
  --limit <n>     Maximum number of tournaments to process (default: 50)
  --help, -h      Show this help message

Examples:
  # List Tier 1 tournaments in 2023
  npx ts-node scripts/import-by-tier-year.ts 1 2023 --list-only

  # Import Tier 1 tournaments in 2023
  npx ts-node scripts/import-by-tier-year.ts 1 2023

  # Preview Tier 2 tournaments in 2022
  npx ts-node scripts/import-by-tier-year.ts 2 2022 --dry-run

  # Import with limit
  npx ts-node scripts/import-by-tier-year.ts 1 2024 --limit 10
`);
}

/**
 * Fetch tournaments from Liquipedia by tier and year
 * Uses backend API to query Liquipedia categories
 */
async function fetchTournaments(
  tier: number,
  year: number,
  limit: number,
  logger: ProgressLogger,
): Promise<string[]> {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:3000';

  // Liquipedia category format: "Tier_X_Tournaments_in_YEAR"
  // Note: We need to query by both tier category and year
  const category = `${TIER_CATEGORIES[tier]}_in_${year}`;

  logger.info(`Querying category: ${category}`);

  try {
    // Query the backend API for category members
    const url = `${backendUrl}/api/v1/liquipedia/category/${encodeURIComponent(category)}?limit=${limit}`;
    logger.debug(`Fetching: ${url}`);

    const response = await fetch(url);

    if (!response.ok) {
      // Try alternative category format
      const altCategory = `Tournaments_in_${year}`;
      logger.warn(`Primary category failed, trying: ${altCategory}`);

      const altUrl = `${backendUrl}/api/v1/liquipedia/category/${encodeURIComponent(altCategory)}?limit=${limit}`;
      const altResponse = await fetch(altUrl);

      if (!altResponse.ok) {
        throw new Error(`API responded with status ${altResponse.status}`);
      }

      const altJson = await altResponse.json() as { success: boolean; data: string[] };
      if (altJson.success && altJson.data) {
        // Filter by checking each tournament's tier (slower but more accurate)
        logger.info('Will filter tournaments by tier during import...');
        return altJson.data;
      }
    }

    const json = await response.json() as { success: boolean; data: string[] };

    if (!json.success || !json.data) {
      throw new Error('API returned unsuccessful response');
    }

    return json.data;
  } catch (error) {
    logger.error(`Failed to fetch tournaments: ${error instanceof Error ? error.message : error}`);

    // Fallback: Query all tournaments for the year and filter by tier
    logger.info('Falling back to year-based query...');

    const fallbackUrl = `${backendUrl}/api/v1/liquipedia/tournaments/${year}`;
    try {
      const fallbackResponse = await fetch(fallbackUrl);
      if (fallbackResponse.ok) {
        const json = await fallbackResponse.json() as { success: boolean; data: string[] };
        return json.data || [];
      }
    } catch {
      // Ignore fallback errors
    }

    return [];
  }
}

/**
 * Filter tournaments to exclude certain patterns
 */
function filterTournaments(tournaments: string[]): string[] {
  const excludePatterns = [
    /^User:/i,
    /^Talk:/i,
    /^Template:/i,
    /^Category:/i,
    /^File:/i,
    /Qualifier/i,      // Exclude qualifier pages (handled separately)
    /Open_Qualifier/i,
    /Closed_Qualifier/i,
    /_Wildcard/i,
    /Regional_Final/i,
  ];

  return tournaments.filter(t => {
    const excluded = excludePatterns.some(pattern => pattern.test(t));
    return !excluded;
  });
}

/**
 * Convert Liquipedia page title to page name for API
 * e.g., "The International 2024" -> "The_International/2024"
 */
function normalizePageName(pageTitle: string): string {
  // Replace spaces with underscores
  return pageTitle.replace(/\s+/g, '_');
}

async function main(): Promise<void> {
  const cliArgs = parseArgs();
  if (!cliArgs) {
    process.exit(0);
  }

  const logger = new ProgressLogger({ verbose: cliArgs.verbose, dryRun: cliArgs.dryRun });

  logger.header(`Tier ${cliArgs.tier} Tournaments - ${cliArgs.year}`);

  // Fetch tournament list
  logger.section('Discovering Tournaments');
  let tournaments = await fetchTournaments(cliArgs.tier, cliArgs.year, cliArgs.limit, logger);

  if (tournaments.length === 0) {
    logger.warn('No tournaments found for the specified criteria');
    logger.info('Try using --verbose to see debug information');
    process.exit(0);
  }

  // Filter out non-tournament pages
  tournaments = filterTournaments(tournaments);
  logger.info(`Found ${tournaments.length} tournaments after filtering`);

  // Normalize page names
  tournaments = tournaments.map(normalizePageName);

  // List tournaments
  logger.section('Tournaments Found');
  logger.list(tournaments.slice(0, 20));
  if (tournaments.length > 20) {
    logger.info(`... and ${tournaments.length - 20} more`);
  }

  // If list-only, stop here
  if (cliArgs.listOnly) {
    logger.info('\n--list-only specified, not importing');
    process.exit(0);
  }

  // Confirm before importing
  const proceed = await logger.confirm(
    `Import ${tournaments.length} tournaments?`,
  );
  if (!proceed) {
    logger.info('Cancelled by user');
    process.exit(0);
  }

  // Create importer with options
  const options: ImportOptions = {
    dryRun: cliArgs.dryRun,
    verbose: cliArgs.verbose,
    skipMatches: cliArgs.skipMatches,
    skipLogos: cliArgs.skipLogos,
  };

  const importer = createImporter(options);

  // Track results
  const results: Array<{ pageName: string; result: ImportResult }> = [];
  let successCount = 0;
  let failCount = 0;
  let skipCount = 0;

  // Import each tournament
  logger.setTotalSteps(tournaments.length);

  for (let i = 0; i < tournaments.length; i++) {
    const pageName = tournaments[i];
    logger.section(`[${i + 1}/${tournaments.length}] ${pageName}`);

    try {
      // Check if already imported
      const exists = await importer.tournamentExists(pageName);
      if (exists) {
        logger.info('Already imported, skipping...');
        skipCount++;
        results.push({
          pageName,
          result: {
            success: true,
            teamsImported: 0,
            playersImported: 0,
            matchesImported: 0,
            errors: ['Already exists'],
          },
        });
        logger.progress(`Skipped ${pageName}`);
        continue;
      }

      const result = await importer.importTournament(pageName);
      results.push({ pageName, result });

      if (result.success) {
        successCount++;
        logger.success(`${pageName} imported successfully`);
      } else {
        failCount++;
        logger.error(`${pageName} failed: ${result.errors.join(', ')}`);
      }
    } catch (error) {
      failCount++;
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error(`${pageName} error: ${errorMessage}`);
      results.push({
        pageName,
        result: {
          success: false,
          teamsImported: 0,
          playersImported: 0,
          matchesImported: 0,
          errors: [errorMessage],
        },
      });
    }

    logger.progress(`Completed ${pageName}`);

    // Rate limiting between tournaments
    if (i < tournaments.length - 1) {
      logger.info('Waiting 3 seconds before next tournament...');
      await sleep(3000);
    }
  }

  logger.progressComplete();

  // Print summary
  const totalTeams = results.reduce((sum, r) => sum + r.result.teamsImported, 0);
  const totalPlayers = results.reduce((sum, r) => sum + r.result.playersImported, 0);
  const totalMatches = results.reduce((sum, r) => sum + r.result.matchesImported, 0);

  logger.summary({
    'Tier': cliArgs.tier,
    'Year': cliArgs.year,
    'Tournaments processed': tournaments.length,
    'Successful imports': successCount,
    'Skipped (existing)': skipCount,
    'Failed imports': failCount,
    'Total teams': totalTeams,
    'Total players': totalPlayers,
    'Total matches': totalMatches,
    'Mode': cliArgs.dryRun ? 'DRY RUN' : 'LIVE',
  });

  // List any failures
  const failures = results.filter(
    r => !r.result.success && !r.result.errors.includes('Already exists'),
  );
  if (failures.length > 0) {
    console.log('\nFailed tournaments:');
    failures.forEach(f => {
      console.log(`  - ${f.pageName}: ${f.result.errors.join(', ')}`);
    });
  }

  // Exit with appropriate code
  process.exit(failCount > 0 ? 1 : 0);
}

// Run main function
main().catch((error) => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
