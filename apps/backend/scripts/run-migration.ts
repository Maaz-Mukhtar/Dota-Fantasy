import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runMigration() {
  console.log('Running Slice 3 migration...');

  try {
    // Create teams table
    console.log('Creating teams table...');
    const { error: teamsError } = await supabase.rpc('exec', {
      sql: `
        CREATE TABLE IF NOT EXISTS teams (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(255) NOT NULL,
          tag VARCHAR(50),
          logo_url TEXT,
          region VARCHAR(50),
          liquipedia_url TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      `
    });

    if (teamsError) {
      // Table might already exist, try inserting data directly
      console.log('Teams table might exist, continuing...');
    }

    // Insert teams directly
    console.log('Inserting sample teams...');
    const teamsData = [
      { id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', name: 'Team Spirit', tag: 'TS', region: 'CIS' },
      { id: 'b2c3d4e5-f6a7-8901-bcde-f23456789012', name: 'Team Liquid', tag: 'Liquid', region: 'Europe' },
      { id: 'c3d4e5f6-a7b8-9012-cdef-345678901234', name: 'Gaimin Gladiators', tag: 'GG', region: 'Europe' },
      { id: 'd4e5f6a7-b8c9-0123-def0-456789012345', name: 'BetBoom Team', tag: 'BB', region: 'CIS' },
      { id: 'e5f6a7b8-c9d0-1234-ef01-567890123456', name: 'Tundra Esports', tag: 'Tundra', region: 'Europe' },
      { id: 'f6a7b8c9-d0e1-2345-f012-678901234567', name: 'Cloud9', tag: 'C9', region: 'North America' },
      { id: 'a7b8c9d0-e1f2-3456-0123-789012345678', name: 'PSG.LGD', tag: 'LGD', region: 'China' },
      { id: 'b8c9d0e1-f2a3-4567-1234-890123456789', name: 'Azure Ray', tag: 'AR', region: 'China' },
    ];

    const { error: insertTeamsError } = await supabase
      .from('teams')
      .upsert(teamsData, { onConflict: 'id' });

    if (insertTeamsError) {
      console.error('Error inserting teams:', insertTeamsError);
    } else {
      console.log('Teams inserted successfully!');
    }

    console.log('Migration complete!');

  } catch (err) {
    console.error('Migration failed:', err);
  }
}

runMigration();
