#!/usr/bin/env ts-node
/**
 * Import a single tournament from Liquipedia
 *
 * Usage:
 *   npx ts-node scripts/import-tournament.ts "The_International/2024"
 *   npx ts-node scripts/import-tournament.ts "Riyadh_Masters/2024" --dry-run
 *   npx ts-node scripts/import-tournament.ts "DreamLeague/Season_22" --verbose
 *   npx ts-node scripts/import-tournament.ts "ESL_One/Birmingham/2024" --skip-matches
 *
 * Options:
 *   --dry-run       Preview changes without modifying database
 *   --verbose       Show detailed debug output
 *   --skip-matches  Skip importing matches from STRATZ
 *   --skip-logos    Skip fetching tournament logos
 *   --force         Force re-import even if tournament exists
 *
 * Prerequisites:
 *   1. Backend must be running: npm run start:dev
 *   2. Environment variables configured (.env file)
 */

import { createImporter, ImportOptions } from './lib/tournament-importer';
import { ProgressLogger } from './lib/progress-logger';
import { generateTournamentId } from './lib/data-mapper';

interface CliArgs {
  pageName: string;
  dryRun: boolean;
  verbose: boolean;
  skipMatches: boolean;
  skipLogos: boolean;
  force: boolean;
}

function parseArgs(): CliArgs | null {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    printUsage();
    return null;
  }

  // Find the page name (first non-flag argument)
  const pageName = args.find(arg => !arg.startsWith('--'));

  if (!pageName) {
    console.error('Error: Tournament page name is required\n');
    printUsage();
    return null;
  }

  return {
    pageName,
    dryRun: args.includes('--dry-run'),
    verbose: args.includes('--verbose'),
    skipMatches: args.includes('--skip-matches'),
    skipLogos: args.includes('--skip-logos'),
    force: args.includes('--force'),
  };
}

function printUsage(): void {
  console.log(`
Usage: npx ts-node scripts/import-tournament.ts <pageName> [options]

Arguments:
  pageName        Liquipedia page name (e.g., "The_International/2024")

Options:
  --dry-run       Preview changes without modifying database
  --verbose       Show detailed debug output
  --skip-matches  Skip importing matches from STRATZ
  --skip-logos    Skip fetching tournament logos
  --force         Force re-import even if tournament exists
  --help, -h      Show this help message

Examples:
  # Import TI 2024
  npx ts-node scripts/import-tournament.ts "The_International/2024"

  # Preview import without changes
  npx ts-node scripts/import-tournament.ts "Riyadh_Masters/2024" --dry-run

  # Import with detailed logging
  npx ts-node scripts/import-tournament.ts "DreamLeague/Season_22" --verbose

  # Import tournament info only (no matches)
  npx ts-node scripts/import-tournament.ts "ESL_One/Birmingham/2024" --skip-matches
`);
}

async function main(): Promise<void> {
  const cliArgs = parseArgs();
  if (!cliArgs) {
    process.exit(0);
  }

  const logger = new ProgressLogger({ verbose: cliArgs.verbose, dryRun: cliArgs.dryRun });

  // Create importer with options
  const options: ImportOptions = {
    dryRun: cliArgs.dryRun,
    verbose: cliArgs.verbose,
    skipMatches: cliArgs.skipMatches,
    skipLogos: cliArgs.skipLogos,
  };

  const importer = createImporter(options);

  // Check if tournament already exists
  if (!cliArgs.force) {
    const exists = await importer.tournamentExists(cliArgs.pageName);
    if (exists) {
      logger.warn(`Tournament already exists: ${cliArgs.pageName}`);
      logger.info('Use --force to re-import');

      const tournamentId = generateTournamentId(cliArgs.pageName);
      logger.info(`Tournament ID: ${tournamentId}`);

      const proceed = await logger.confirm('Re-import tournament?');
      if (!proceed) {
        logger.info('Cancelled by user');
        process.exit(0);
      }
    }
  }

  // Run import
  const result = await importer.importTournament(cliArgs.pageName);

  // Exit with appropriate code
  if (result.success) {
    logger.success('Import completed successfully!');
    process.exit(0);
  } else {
    logger.error('Import failed with errors:');
    result.errors.forEach(err => logger.error(`  - ${err}`));
    process.exit(1);
  }
}

// Run main function
main().catch((error) => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
