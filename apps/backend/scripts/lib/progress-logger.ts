/**
 * Progress logging utilities for CLI scripts
 */

import * as readline from 'readline';

export interface ProgressLoggerOptions {
  verbose?: boolean;
  dryRun?: boolean;
}

export class ProgressLogger {
  private verbose: boolean;
  private dryRun: boolean;
  private currentStep = 0;
  private totalSteps = 0;
  private startTime = Date.now();

  constructor(options: ProgressLoggerOptions = {}) {
    this.verbose = options.verbose ?? false;
    this.dryRun = options.dryRun ?? false;
  }

  /**
   * Print header with script name
   */
  header(title: string): void {
    const line = '='.repeat(50);
    console.log(`\n${line}`);
    console.log(`  ${title}`);
    if (this.dryRun) {
      console.log('  [DRY RUN MODE - No changes will be made]');
    }
    console.log(`${line}\n`);
    this.startTime = Date.now();
  }

  /**
   * Print section header
   */
  section(title: string): void {
    console.log(`\n--- ${title} ---\n`);
  }

  /**
   * Print info message
   */
  info(message: string): void {
    console.log(`[INFO] ${message}`);
  }

  /**
   * Print success message
   */
  success(message: string): void {
    console.log(`[SUCCESS] ${message}`);
  }

  /**
   * Print warning message
   */
  warn(message: string): void {
    console.log(`[WARN] ${message}`);
  }

  /**
   * Print error message
   */
  error(message: string, err?: Error): void {
    console.error(`[ERROR] ${message}`);
    if (err && this.verbose) {
      console.error(err.stack || err.message);
    }
  }

  /**
   * Print debug message (only in verbose mode)
   */
  debug(message: string): void {
    if (this.verbose) {
      console.log(`[DEBUG] ${message}`);
    }
  }

  /**
   * Set total steps for progress tracking
   */
  setTotalSteps(total: number): void {
    this.totalSteps = total;
    this.currentStep = 0;
  }

  /**
   * Increment and show progress
   */
  progress(message: string): void {
    this.currentStep++;
    const percent = this.totalSteps
      ? Math.round((this.currentStep / this.totalSteps) * 100)
      : 0;
    const progressBar = this.createProgressBar(percent);

    // Clear line and write progress
    readline.clearLine(process.stdout, 0);
    readline.cursorTo(process.stdout, 0);
    process.stdout.write(`${progressBar} ${message}`);
  }

  /**
   * Complete progress (new line)
   */
  progressComplete(): void {
    console.log(); // New line after progress
  }

  /**
   * Create ASCII progress bar
   */
  private createProgressBar(percent: number): string {
    const width = 20;
    const filled = Math.round((percent / 100) * width);
    const empty = width - filled;
    return `[${'='.repeat(filled)}${' '.repeat(empty)}] ${percent.toString().padStart(3)}%`;
  }

  /**
   * Print list of items
   */
  list(items: string[], prefix = '  '): void {
    items.forEach((item, i) => {
      console.log(`${prefix}${i + 1}. ${item}`);
    });
  }

  /**
   * Print summary table
   */
  summary(data: Record<string, number | string>): void {
    const elapsed = ((Date.now() - this.startTime) / 1000).toFixed(1);

    console.log('\n========== SUMMARY ==========\n');
    Object.entries(data).forEach(([key, value]) => {
      console.log(`  ${key.padEnd(25)} ${value}`);
    });
    console.log(`  ${'Elapsed time'.padEnd(25)} ${elapsed}s`);
    console.log('\n=============================\n');
  }

  /**
   * Prompt user for confirmation
   */
  async confirm(question: string): Promise<boolean> {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    return new Promise((resolve) => {
      rl.question(`\n${question} (y/N): `, (answer) => {
        rl.close();
        resolve(answer.toLowerCase() === 'y');
      });
    });
  }

  /**
   * Print tournament preview
   */
  tournamentPreview(tournament: {
    name: string;
    tier?: string;
    prizePool?: number | string;
    startDate?: string;
    endDate?: string;
    teams?: number;
  }): void {
    console.log(`\n  Tournament: ${tournament.name}`);
    if (tournament.tier) console.log(`  Tier:       ${tournament.tier}`);
    if (tournament.prizePool) console.log(`  Prize Pool: $${tournament.prizePool.toLocaleString()}`);
    if (tournament.startDate) console.log(`  Start:      ${tournament.startDate}`);
    if (tournament.endDate) console.log(`  End:        ${tournament.endDate}`);
    if (tournament.teams) console.log(`  Teams:      ${tournament.teams}`);
    console.log();
  }
}

/**
 * Create a spinner for long-running operations
 */
export function createSpinner(message: string): {
  stop: () => void;
  update: (msg: string) => void;
} {
  const frames = ['|', '/', '-', '\\'];
  let i = 0;
  let currentMessage = message;

  const interval = setInterval(() => {
    readline.clearLine(process.stdout, 0);
    readline.cursorTo(process.stdout, 0);
    process.stdout.write(`${frames[i]} ${currentMessage}`);
    i = (i + 1) % frames.length;
  }, 100);

  return {
    stop: () => {
      clearInterval(interval);
      readline.clearLine(process.stdout, 0);
      readline.cursorTo(process.stdout, 0);
    },
    update: (msg: string) => {
      currentMessage = msg;
    },
  };
}

/**
 * Sleep helper
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
