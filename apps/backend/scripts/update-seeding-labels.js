require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

// Mapping of team matchups to their seeding decider labels
// Based on Liquipedia TI 2023 Group Stage data
const seedingLabels = [
  { teams: ["team spirit", "shopify rebellion"], label: "A1 vs B3/B4" },
  { teams: ["tsm", "virtus.pro"], label: "D2 vs C3/C4" },
  { teams: ["team liquid", "evil geniuses"], label: "B1 vs A3/A4" },
  { teams: ["gaimin gladiators", "talon esports"], label: "C2 vs D3/D4" },
  { teams: ["lgd gaming", "keyd stars"], label: "C1 vs D3/D4" },
  { teams: ["betboom team", "9pandas"], label: "B2 vs A3/A4" },
  { teams: ["tundra esports", "nouns"], label: "D1 vs C3/C4" },
  { teams: ["entity", "azure ray"], label: "A2 vs B3/B4" },
];

async function main() {
  // Get TI 2023 tournament ID
  const { data: tournament } = await supabase
    .from("tournaments")
    .select("id")
    .ilike("name", "%International 2023%")
    .single();

  console.log("Tournament ID:", tournament.id);

  // Get all Seeding Decider matches with team info
  const { data: matches } = await supabase
    .from("matches")
    .select("id, round, team1:teams!matches_team1_id_fkey(name), team2:teams!matches_team2_id_fkey(name)")
    .eq("tournament_id", tournament.id)
    .eq("stage", "Group Stage")
    .eq("round", "Seeding Decider");

  console.log("Found", matches?.length, "Seeding Decider matches");

  let updated = 0;
  for (const match of matches || []) {
    const team1Name = match.team1?.name?.toLowerCase() || "";
    const team2Name = match.team2?.name?.toLowerCase() || "";

    // Find matching label
    const labelInfo = seedingLabels.find(s =>
      (team1Name.includes(s.teams[0]) || team1Name.includes(s.teams[1])) &&
      (team2Name.includes(s.teams[0]) || team2Name.includes(s.teams[1]))
    );

    if (labelInfo) {
      const { error } = await supabase
        .from("matches")
        .update({ round: labelInfo.label })
        .eq("id", match.id);

      if (!error) {
        updated++;
        console.log(`  ${match.team1?.name} vs ${match.team2?.name} -> ${labelInfo.label}`);
      }
    } else {
      console.log(`  No label found for: ${team1Name} vs ${team2Name}`);
    }
  }

  console.log("\nUpdated", updated, "matches with seeding labels");
}

main().catch(console.error);
