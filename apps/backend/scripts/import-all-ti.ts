#!/usr/bin/env ts-node
/**
 * Import all The International tournaments from Liquipedia
 *
 * Usage:
 *   npx ts-node scripts/import-all-ti.ts                    # All TIs (2011-2025)
 *   npx ts-node scripts/import-all-ti.ts --start 2020      # TIs from 2020 onwards
 *   npx ts-node scripts/import-all-ti.ts --end 2019        # TIs up to 2019
 *   npx ts-node scripts/import-all-ti.ts --dry-run         # Preview without changes
 *   npx ts-node scripts/import-all-ti.ts --verbose         # Detailed output
 *
 * Options:
 *   --start <year>  Start from this year (inclusive)
 *   --end <year>    End at this year (inclusive)
 *   --dry-run       Preview changes without modifying database
 *   --verbose       Show detailed debug output
 *   --skip-matches  Skip importing matches from STRATZ
 *   --skip-logos    Skip fetching tournament logos
 *
 * Prerequisites:
 *   1. Backend must be running: npm run start:dev
 *   2. Environment variables configured (.env file)
 */

import { createImporter, ImportOptions, ImportResult } from './lib/tournament-importer';
import { ProgressLogger, sleep } from './lib/progress-logger';

// The International page names by year
// Note: TI was not held in 2020 due to COVID-19
const TI_TOURNAMENTS: Record<number, string> = {
  2011: 'The_International/2011',
  2012: 'The_International/2012',
  2013: 'The_International/2013',
  2014: 'The_International/2014',
  2015: 'The_International/2015',
  2016: 'The_International/2016',
  2017: 'The_International/2017',
  2018: 'The_International/2018',
  2019: 'The_International/2019',
  // 2020: No TI (COVID-19)
  2021: 'The_International/2021',
  2022: 'The_International/2022',
  2023: 'The_International/2023',
  2024: 'The_International/2024',
  2025: 'The_International/2025',
};

interface CliArgs {
  startYear: number;
  endYear: number;
  dryRun: boolean;
  verbose: boolean;
  skipMatches: boolean;
  skipLogos: boolean;
}

function parseArgs(): CliArgs | null {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    printUsage();
    return null;
  }

  // Parse start year
  const startIndex = args.indexOf('--start');
  let startYear = 2011; // First TI
  if (startIndex !== -1 && args[startIndex + 1]) {
    startYear = parseInt(args[startIndex + 1], 10);
    if (isNaN(startYear)) {
      console.error('Error: Invalid start year\n');
      printUsage();
      return null;
    }
  }

  // Parse end year
  const endIndex = args.indexOf('--end');
  let endYear = 2025; // Latest TI
  if (endIndex !== -1 && args[endIndex + 1]) {
    endYear = parseInt(args[endIndex + 1], 10);
    if (isNaN(endYear)) {
      console.error('Error: Invalid end year\n');
      printUsage();
      return null;
    }
  }

  return {
    startYear,
    endYear,
    dryRun: args.includes('--dry-run'),
    verbose: args.includes('--verbose'),
    skipMatches: args.includes('--skip-matches'),
    skipLogos: args.includes('--skip-logos'),
  };
}

function printUsage(): void {
  console.log(`
Usage: npx ts-node scripts/import-all-ti.ts [options]

Options:
  --start <year>  Start from this year (default: 2011)
  --end <year>    End at this year (default: 2025)
  --dry-run       Preview changes without modifying database
  --verbose       Show detailed debug output
  --skip-matches  Skip importing matches from STRATZ
  --skip-logos    Skip fetching tournament logos
  --help, -h      Show this help message

Examples:
  # Import all TIs (2011-2025, skipping 2020)
  npx ts-node scripts/import-all-ti.ts

  # Import TIs from 2020 onwards
  npx ts-node scripts/import-all-ti.ts --start 2020

  # Import TIs up to 2019
  npx ts-node scripts/import-all-ti.ts --end 2019

  # Preview import without changes
  npx ts-node scripts/import-all-ti.ts --dry-run

Note: The International was not held in 2020 due to COVID-19.
`);
}

async function main(): Promise<void> {
  const cliArgs = parseArgs();
  if (!cliArgs) {
    process.exit(0);
  }

  const logger = new ProgressLogger({ verbose: cliArgs.verbose, dryRun: cliArgs.dryRun });

  // Get tournaments in year range
  const years = Object.keys(TI_TOURNAMENTS)
    .map(Number)
    .filter(year => year >= cliArgs.startYear && year <= cliArgs.endYear)
    .sort((a, b) => a - b);

  if (years.length === 0) {
    logger.error(`No TI tournaments found in range ${cliArgs.startYear}-${cliArgs.endYear}`);
    process.exit(1);
  }

  logger.header('The International Batch Import');
  logger.info(`Importing ${years.length} tournaments: ${years.join(', ')}`);

  if (cliArgs.dryRun) {
    logger.warn('DRY RUN MODE - No changes will be made');
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
  const results: Array<{ year: number; result: ImportResult }> = [];
  let successCount = 0;
  let failCount = 0;

  // Import each tournament
  logger.setTotalSteps(years.length);

  for (const year of years) {
    const pageName = TI_TOURNAMENTS[year];
    logger.section(`TI ${year}`);
    logger.info(`Page: ${pageName}`);

    try {
      const result = await importer.importTournament(pageName);
      results.push({ year, result });

      if (result.success) {
        successCount++;
        logger.success(`TI ${year} imported successfully`);
      } else {
        failCount++;
        logger.error(`TI ${year} failed: ${result.errors.join(', ')}`);
      }
    } catch (error) {
      failCount++;
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error(`TI ${year} error: ${errorMessage}`);
      results.push({
        year,
        result: {
          success: false,
          teamsImported: 0,
          playersImported: 0,
          matchesImported: 0,
          errors: [errorMessage],
        },
      });
    }

    logger.progress(`Completed TI ${year}`);

    // Rate limiting between tournaments
    if (year !== years[years.length - 1]) {
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
    'Tournaments processed': years.length,
    'Successful imports': successCount,
    'Failed imports': failCount,
    'Total teams': totalTeams,
    'Total players': totalPlayers,
    'Total matches': totalMatches,
    'Mode': cliArgs.dryRun ? 'DRY RUN' : 'LIVE',
  });

  // List any failures
  const failures = results.filter(r => !r.result.success);
  if (failures.length > 0) {
    console.log('\nFailed tournaments:');
    failures.forEach(f => {
      console.log(`  - TI ${f.year}: ${f.result.errors.join(', ')}`);
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
