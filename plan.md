# Dota 2 Fantasy Points Mobile Application

## Business, Technical & Development Plan

**Version 1.0 | January 2026**

---

# Table of Contents

1. [Executive Summary](#part-1-business-plan)
2. [Market Analysis](#2-market-analysis)
3. [Business Model](#3-business-model)
4. [System Architecture](#part-2-technical-plan)
5. [Technology Stack](#42-technology-stack)
6. [Data Architecture](#43-data-architecture)
7. [API Design](#44-api-design)
8. [Fantasy Points System](#45-fantasy-points-system)
9. [Development Approach](#part-3-development-plan)
10. [MVP Slice Breakdown](#52-mvp-slice-breakdown)
11. [Post-MVP Roadmap](#6-post-mvp-roadmap)
12. [Timeline Summary](#7-timeline-summary)
13. [Risks & Mitigations](#8-risks--mitigations)
14. [Success Criteria](#9-success-criteria)
15. [Appendix: API Integration Details](#appendix-a-api-integration-details)

---

# PART 1: BUSINESS PLAN

## 1. Executive Summary

### 1.1 Vision Statement

To become the premier fantasy sports platform for Dota 2 esports, providing fans with an engaging way to connect with professional tournaments while building a sustainable, community-driven business.

### 1.2 Mission Statement

Deliver an intuitive, data-rich fantasy experience for Dota 2 enthusiasts that enhances their connection to DPC tournaments through strategic team building, real-time scoring, and competitive leagues.

### 1.3 Product Overview

Dota 2 Fantasy Points is a mobile application that allows users to create fantasy teams using professional Dota 2 players, earn points based on real match performance, and compete against friends and the global community during DPC tournaments.

### 1.4 Key Differentiators

- **DPC Focus:** Specialized coverage of official Dota Pro Circuit tournaments
- **Modern Tech Stack:** Flutter-based cross-platform app with seamless iOS, Android, and web experience
- **Real-Time Data:** Integration with STRATZ for comprehensive match statistics
- **Community-First:** Free core experience with premium features for dedicated fans

---

## 2. Market Analysis

### 2.1 Market Size

- Dota 2 has approximately **10-15 million monthly active players** globally
- The International 2024 prize pool exceeded **$40 million**
- Esports fantasy market projected to reach **$5+ billion by 2027**
- DPC tournaments attract **millions of viewers** per season

### 2.2 Target Audience

| Segment | Description |
|---------|-------------|
| **Primary** | Dedicated Dota 2 fans (18-35) who follow professional esports |
| **Secondary** | Casual players interested in the competitive scene |
| **Tertiary** | Fantasy sports enthusiasts looking to expand into esports |

### 2.3 Competitive Landscape

| Competitor | Strengths | Weaknesses |
|------------|-----------|------------|
| **Valve Fantasy (In-Game)** | Official, integrated with client | Limited to TI, basic features, no mobile app |
| **DraftKings/FanDuel** | Established brand, legal framework | Limited Dota coverage, real-money focus |
| **Existing Dota 2 Fantasy Apps** | Some exist on app stores | Outdated, poor UX, limited data |

### 2.4 Our Competitive Advantage

- Dedicated focus on Dota 2 DPC ecosystem (not spread across multiple games)
- Modern, polished mobile-first experience
- Deep integration with best-in-class data sources (Liquipedia + STRATZ)
- Free-to-play model with optional premium features
- Community features (leagues, social sharing, discussions)

---

## 3. Business Model

### 3.1 Revenue Streams

#### 3.1.1 Freemium Subscription

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | 1 fantasy team, basic stats, public leagues, ads |
| **Pro** | $4.99/month | Unlimited teams, advanced stats, private leagues, no ads |
| **Season Pass** | $14.99/season | Pro features + exclusive badges, early access, priority support |

#### 3.1.2 Additional Revenue

- **In-App Purchases:** Cosmetic items (team badges, profile frames, themes)
- **Advertising:** Non-intrusive ads for free users (esports-related sponsors)
- **Partnerships:** Tournament organizers, team sponsors, betting platforms (where legal)
- **Merchandise:** Future potential for branded merchandise

### 3.2 Cost Structure

| Category | MVP Phase | Growth Phase |
|----------|-----------|--------------|
| API Costs (Liquipedia, STRATZ) | $0-100/month | $500-2000/month |
| Cloud Infrastructure | $50-150/month | $500-2000/month |
| Apple Developer Account | $99/year | $99/year |
| Google Play (future) | $25 one-time | $25 one-time |
| Development (if outsourced) | Variable | Variable |

### 3.3 Key Metrics (KPIs)

- Monthly Active Users (MAU)
- Daily Active Users (DAU)
- User Retention (Day 1, Day 7, Day 30)
- Conversion Rate (Free to Pro)
- Average Revenue Per User (ARPU)
- Fantasy Teams Created per Tournament
- App Store Rating & Reviews

---

# PART 2: TECHNICAL PLAN

## 4. System Architecture

### 4.1 High-Level Architecture

The system follows a three-tier architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Flutter iOS   │  │ Flutter Android │  │   Flutter Web   │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
└───────────┼─────────────────────┼─────────────────────┼─────────┘
            │                     │                     │
            └─────────────────────┼─────────────────────┘
                                  │ HTTPS/WSS
┌─────────────────────────────────┼───────────────────────────────┐
│                      APPLICATION LAYER                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  REST API       │  │  Background     │  │   WebSocket     │ │
│  │  (NestJS)       │  │  Workers        │  │   Server        │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
└───────────┼─────────────────────┼─────────────────────┼─────────┘
            │                     │                     │
┌───────────┼─────────────────────┼─────────────────────┼─────────┐
│           │           DATA LAYER                      │         │
│  ┌────────▼────────┐  ┌────────▼────────┐  ┌─────────▼───────┐ │
│  │   PostgreSQL    │  │     Redis       │  │  External APIs  │ │
│  │   (Primary DB)  │  │    (Cache)      │  │ Liquipedia/     │ │
│  │                 │  │                 │  │ STRATZ          │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Technology Stack

#### 4.2.1 Mobile Application

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod 2.x (recommended) or BLoC |
| Navigation | GoRouter |
| HTTP Client | Dio with interceptors |
| Local Storage | Hive (offline data) + SharedPreferences (settings) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Analytics | Firebase Analytics + Crashlytics |

#### 4.2.2 Backend Services

| Component | Technology |
|-----------|------------|
| Runtime | Node.js 20 LTS with TypeScript |
| API Framework | NestJS (structured) or Fastify (lightweight) |
| Database ORM | Prisma |
| Validation | Zod or class-validator |
| Job Queue | BullMQ (Redis-based) |
| Real-time | Socket.IO or native WebSockets |
| Authentication | JWT + Firebase Auth (social login) |

#### 4.2.3 Infrastructure

| Component | Technology |
|-----------|------------|
| Cloud Provider | AWS (recommended) or Google Cloud |
| Container Orchestration | Docker + ECS or Cloud Run |
| Database | AWS RDS PostgreSQL or Supabase |
| Cache | AWS ElastiCache Redis or Upstash |
| CDN | CloudFront or Cloudflare |
| CI/CD | GitHub Actions |
| Monitoring | Datadog or AWS CloudWatch |

---

## 4.3 Data Architecture

### 4.3.1 Core Database Schema

#### Tournament Domain

```sql
-- Tournaments
CREATE TABLE tournaments (
    id              UUID PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    tier            VARCHAR(20) NOT NULL,  -- 'tier1', 'tier2', 'tier3', 'major', 'ti'
    start_date      DATE NOT NULL,
    end_date        DATE,
    prize_pool      DECIMAL(12, 2),
    format          TEXT,
    liquipedia_url  VARCHAR(500),
    status          VARCHAR(20) DEFAULT 'upcoming',  -- 'upcoming', 'ongoing', 'completed'
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- Teams
CREATE TABLE teams (
    id              UUID PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    tag             VARCHAR(10),
    logo_url        VARCHAR(500),
    region          VARCHAR(50),
    liquipedia_url  VARCHAR(500),
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Players
CREATE TABLE players (
    id              UUID PRIMARY KEY,
    nickname        VARCHAR(100) NOT NULL,
    real_name       VARCHAR(255),
    role            VARCHAR(20),  -- 'carry', 'mid', 'offlane', 'support4', 'support5'
    team_id         UUID REFERENCES teams(id),
    country         VARCHAR(100),
    avatar_url      VARCHAR(500),
    stratz_id       BIGINT,
    steam_id        BIGINT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Matches
CREATE TABLE matches (
    id              UUID PRIMARY KEY,
    tournament_id   UUID REFERENCES tournaments(id),
    team1_id        UUID REFERENCES teams(id),
    team2_id        UUID REFERENCES teams(id),
    scheduled_at    TIMESTAMP,
    status          VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'live', 'completed'
    winner_id       UUID REFERENCES teams(id),
    team1_score     INTEGER DEFAULT 0,
    team2_score     INTEGER DEFAULT 0,
    best_of         INTEGER DEFAULT 3,
    stage           VARCHAR(100),  -- 'group_a', 'playoffs', 'grand_final'
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Games (individual games within a match)
CREATE TABLE games (
    id              UUID PRIMARY KEY,
    match_id        UUID REFERENCES matches(id),
    game_number     INTEGER NOT NULL,
    radiant_team_id UUID REFERENCES teams(id),
    dire_team_id    UUID REFERENCES teams(id),
    winner_id       UUID REFERENCES teams(id),
    duration        INTEGER,  -- seconds
    stratz_match_id BIGINT,
    created_at      TIMESTAMP DEFAULT NOW()
);
```

#### Fantasy Domain

```sql
-- Fantasy Leagues
CREATE TABLE fantasy_leagues (
    id              UUID PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    tournament_id   UUID REFERENCES tournaments(id),
    owner_id        UUID REFERENCES users(id),
    is_public       BOOLEAN DEFAULT true,
    max_members     INTEGER DEFAULT 100,
    invite_code     VARCHAR(20) UNIQUE,
    settings        JSONB,  -- scoring rules, roster rules, etc.
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Fantasy Teams
CREATE TABLE fantasy_teams (
    id              UUID PRIMARY KEY,
    user_id         UUID REFERENCES users(id),
    league_id       UUID REFERENCES fantasy_leagues(id),
    name            VARCHAR(255) NOT NULL,
    total_points    DECIMAL(10, 2) DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, league_id)
);

-- Fantasy Roster (player selections)
CREATE TABLE fantasy_rosters (
    id              UUID PRIMARY KEY,
    fantasy_team_id UUID REFERENCES fantasy_teams(id),
    player_id       UUID REFERENCES players(id),
    slot            VARCHAR(20) NOT NULL,  -- 'carry', 'mid', 'offlane', 'support4', 'support5'
    is_captain      BOOLEAN DEFAULT false,  -- 2x points
    locked_at       TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(fantasy_team_id, slot)
);

-- Player Stats (per game)
CREATE TABLE player_stats (
    id              UUID PRIMARY KEY,
    player_id       UUID REFERENCES players(id),
    game_id         UUID REFERENCES games(id),
    kills           INTEGER DEFAULT 0,
    deaths          INTEGER DEFAULT 0,
    assists         INTEGER DEFAULT 0,
    last_hits       INTEGER DEFAULT 0,
    denies          INTEGER DEFAULT 0,
    gpm             INTEGER DEFAULT 0,
    xpm             INTEGER DEFAULT 0,
    hero_damage     INTEGER DEFAULT 0,
    tower_damage    INTEGER DEFAULT 0,
    hero_healing    INTEGER DEFAULT 0,
    stuns           DECIMAL(8, 2) DEFAULT 0,  -- seconds
    obs_placed      INTEGER DEFAULT 0,
    camps_stacked   INTEGER DEFAULT 0,
    first_blood     BOOLEAN DEFAULT false,
    hero_id         INTEGER,
    is_winner       BOOLEAN DEFAULT false,
    raw_data        JSONB,  -- full STRATZ response
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(player_id, game_id)
);

-- Fantasy Points (calculated)
CREATE TABLE fantasy_points (
    id              UUID PRIMARY KEY,
    roster_id       UUID REFERENCES fantasy_rosters(id),
    game_id         UUID REFERENCES games(id),
    points          DECIMAL(10, 2) NOT NULL,
    breakdown       JSONB,  -- detailed point breakdown
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(roster_id, game_id)
);
```

#### User Domain

```sql
-- Users
CREATE TABLE users (
    id              UUID PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,
    username        VARCHAR(100) UNIQUE NOT NULL,
    password_hash   VARCHAR(255),
    avatar_url      VARCHAR(500),
    auth_provider   VARCHAR(50),  -- 'email', 'google', 'steam', 'discord'
    auth_provider_id VARCHAR(255),
    created_at      TIMESTAMP DEFAULT NOW()
);

-- User Profiles
CREATE TABLE user_profiles (
    user_id             UUID PRIMARY KEY REFERENCES users(id),
    display_name        VARCHAR(255),
    bio                 TEXT,
    favorite_team_id    UUID REFERENCES teams(id),
    subscription_tier   VARCHAR(20) DEFAULT 'free',  -- 'free', 'pro', 'season'
    subscription_expires TIMESTAMP,
    total_fantasy_points DECIMAL(12, 2) DEFAULT 0,
    tournaments_played  INTEGER DEFAULT 0
);

-- User Settings
CREATE TABLE user_settings (
    user_id                 UUID PRIMARY KEY REFERENCES users(id),
    notifications_enabled   BOOLEAN DEFAULT true,
    notify_match_start      BOOLEAN DEFAULT true,
    notify_match_end        BOOLEAN DEFAULT true,
    notify_roster_lock      BOOLEAN DEFAULT true,
    theme                   VARCHAR(20) DEFAULT 'system',
    language                VARCHAR(10) DEFAULT 'en'
);

-- Device Tokens (for push notifications)
CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY,
    user_id     UUID REFERENCES users(id),
    token       VARCHAR(500) NOT NULL,
    platform    VARCHAR(20),  -- 'ios', 'android', 'web'
    created_at  TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, token)
);
```

### 4.3.2 Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DATA PIPELINE                                  │
└─────────────────────────────────────────────────────────────────────────┘

1. TOURNAMENT DATA (Liquipedia → Database)
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │ Cron Job    │────▶│ Liquipedia  │────▶│ PostgreSQL  │
   │ (hourly)    │     │ API         │     │             │
   └─────────────┘     └─────────────┘     └─────────────┘
   
2. MATCH STATS (STRATZ → Database → Fantasy Points)
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │ Match End   │────▶│ STRATZ      │────▶│ Player      │────▶│ Fantasy     │
   │ Trigger     │     │ GraphQL     │     │ Stats       │     │ Points Calc │
   └─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘

3. APP DATA FLOW (Database → Cache → API → App)
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │ PostgreSQL  │────▶│ Redis       │────▶│ REST API    │────▶│ Flutter     │
   │             │     │ Cache       │     │             │     │ App         │
   └─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘

4. NOTIFICATIONS
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │ Event       │────▶│ FCM         │────▶│ User        │
   │ Trigger     │     │ Service     │     │ Device      │
   └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 4.4 API Design

### 4.4.1 RESTful Endpoints

#### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Create new account |
| POST | `/api/v1/auth/login` | Login with credentials |
| POST | `/api/v1/auth/logout` | Logout (invalidate token) |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| GET | `/api/v1/auth/me` | Get current user |

#### Tournaments

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments` | List tournaments (filterable by tier, status) |
| GET | `/api/v1/tournaments/:id` | Tournament details with teams, schedule |
| GET | `/api/v1/tournaments/:id/teams` | Teams participating in tournament |
| GET | `/api/v1/tournaments/:id/matches` | All matches for a tournament |
| GET | `/api/v1/tournaments/:id/standings` | Group standings / bracket |

#### Players

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/players` | List players (filterable by team, role) |
| GET | `/api/v1/players/:id` | Player details |
| GET | `/api/v1/players/:id/stats` | Player statistics and fantasy history |
| GET | `/api/v1/players/:id/fantasy-avg` | Average fantasy points per game |

#### Fantasy

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/fantasy/leagues` | User's fantasy leagues |
| POST | `/api/v1/fantasy/leagues` | Create a new fantasy league |
| GET | `/api/v1/fantasy/leagues/:id` | League details |
| POST | `/api/v1/fantasy/leagues/:id/join` | Join league with invite code |
| GET | `/api/v1/fantasy/leagues/:id/leaderboard` | League standings |
| GET | `/api/v1/fantasy/teams` | User's fantasy teams |
| POST | `/api/v1/fantasy/teams` | Create fantasy team |
| GET | `/api/v1/fantasy/teams/:id` | Fantasy team details and roster |
| PUT | `/api/v1/fantasy/teams/:id/roster` | Update fantasy roster |
| GET | `/api/v1/fantasy/teams/:id/points` | Points breakdown by game |

#### Matches

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/matches/:id` | Match details |
| GET | `/api/v1/matches/:id/games` | Games within a match |
| GET | `/api/v1/matches/:id/stats` | Player stats for the match |

### 4.4.2 Response Format

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150
  }
}
```

Error Response:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid roster selection",
    "details": [
      { "field": "slot", "message": "Slot 'carry' is already filled" }
    ]
  }
}
```

---

## 4.5 Fantasy Points System

### 4.5.1 Scoring Rules

Points are calculated per game, summed across all games in a match:

| Stat | Points | Notes |
|------|--------|-------|
| Kill | +0.3 | Per kill |
| Death | -0.3 | Per death |
| Assist | +0.15 | Per assist |
| Last Hit | +0.003 | Per last hit |
| Deny | +0.003 | Per deny |
| GPM (Gold Per Minute) | +0.002 | Per GPM point |
| XPM (XP Per Minute) | +0.001 | Per XPM point |
| Tower Damage | +0.001 | Per damage point |
| Hero Damage | +0.0001 | Per damage point |
| Hero Healing | +0.0002 | Per heal point |
| Stuns | +0.05 | Per second stunned |
| Observer Wards Placed | +0.25 | Per ward |
| Camps Stacked | +0.3 | Per stack |
| First Blood | +1.0 | Bonus for getting FB |
| Win Bonus | +3.0 | If player's team wins game |

### 4.5.2 Multipliers

| Modifier | Effect |
|----------|--------|
| **Captain** | 2x points for the selected captain |
| **Silver Captain** (Pro feature) | 1.5x points for secondary captain |

### 4.5.3 Example Calculation

```
Player: Yatoro (Carry)
Game Stats:
- Kills: 12, Deaths: 3, Assists: 8
- Last Hits: 450, GPM: 720, XPM: 650
- Tower Damage: 8500, Hero Damage: 42000
- Won the game, Got First Blood

Calculation:
  Kills:        12 × 0.3    = 3.60
  Deaths:       3 × -0.3    = -0.90
  Assists:      8 × 0.15    = 1.20
  Last Hits:    450 × 0.003 = 1.35
  GPM:          720 × 0.002 = 1.44
  XPM:          650 × 0.001 = 0.65
  Tower Dmg:    8500 × 0.001= 8.50
  Hero Dmg:     42000×0.0001= 4.20
  First Blood:              = 1.00
  Win Bonus:                = 3.00
  ─────────────────────────────────
  TOTAL:                    = 24.04 points

If Captain: 24.04 × 2 = 48.08 points
```

### 4.5.4 Roster Lock Rules

- Rosters lock **30 minutes before** the first match of each day
- Users can make unlimited changes until lock time
- Locked rosters cannot be modified until the next day's lock
- If a player doesn't play (substitute), they earn 0 points

---

# PART 3: DEVELOPMENT PLAN

## 5. Development Approach: Vertical Slices

### 5.1 What Are Vertical Slices?

Vertical slices are fully functional features that cut through all layers of the application (UI, API, database, external integrations). Each slice delivers user value independently and can be tested end-to-end.

**Benefits:**
- Demonstrates progress with working software
- Enables early user testing and feedback
- Reduces integration risk
- Allows parallel development when team grows
- Each slice is potentially shippable

### 5.2 MVP Slice Breakdown

The MVP consists of **8 vertical slices** delivered across **4 phases**:

---

## PHASE 1: FOUNDATION (Weeks 1-4)

### Slice 1: Project Setup & Authentication

**Duration:** Week 1

**User Story:** As a user, I can download the app and create an account to save my progress.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Project setup, folder structure, Riverpod config, splash screen, auth screens (login/signup), Firebase Auth integration |
| **Backend** | NestJS project setup, Docker config, Prisma setup, User model, JWT middleware, auth endpoints (`/register`, `/login`, `/me`) |
| **Database** | PostgreSQL setup, User table, UserProfile table, migrations |
| **Infra** | GitHub repo, CI pipeline, dev environment on AWS/Railway |

**Acceptance Criteria:** User can sign up with email, log in, and see their profile.

**Technical Details:**
```
flutter/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── features/
│   │   └── auth/
│   │       ├── data/
│   │       │   ├── auth_repository.dart
│   │       │   └── auth_api.dart
│   │       ├── domain/
│   │       │   └── user.dart
│   │       └── presentation/
│   │           ├── login_screen.dart
│   │           ├── signup_screen.dart
│   │           └── auth_controller.dart
│   ├── core/
│   │   ├── network/
│   │   │   └── dio_client.dart
│   │   └── storage/
│   │       └── secure_storage.dart
│   └── shared/
│       └── widgets/
```

---

### Slice 2: Tournament List

**Duration:** Week 2

**User Story:** As a user, I can see a list of upcoming and ongoing DPC tournaments.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Tournament list screen, tournament card component, tier badges, pull-to-refresh, loading states, error handling |
| **Backend** | Tournament model, `GET /tournaments` endpoint with filtering, Liquipedia service integration |
| **Database** | Tournament table, seed script with sample data |
| **Integration** | Liquipedia API wrapper, scheduled job to fetch tournaments (cron) |

**Acceptance Criteria:** User sees list of DPC tournaments with name, dates, tier, and status. List updates automatically.

**UI Components:**
- `TournamentListScreen` - Main screen with list
- `TournamentCard` - Individual tournament display
- `TierBadge` - Visual indicator for tier (Tier 1 = gold, Tier 2 = silver, etc.)
- `StatusChip` - "Upcoming", "Live", "Completed"

---

### Slice 3: Tournament Details

**Duration:** Weeks 3-4

**User Story:** As a user, I can view tournament details including participating teams, format, and schedule.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Tournament detail screen (tabs: Overview, Teams, Schedule), team list with logos, match schedule with dates/times, group stage tables |
| **Backend** | Team model, Match model, `GET /tournaments/:id`, `GET /tournaments/:id/teams`, `GET /tournaments/:id/matches` |
| **Database** | Team table, Match table, TournamentTeam junction table |
| **Integration** | Liquipedia scraper for teams, schedule, groups |

**Acceptance Criteria:** User can tap tournament, see overview, browse teams, and view match schedule.

**Screen Structure:**
```
TournamentDetailScreen
├── TabBar
│   ├── Overview Tab
│   │   ├── Tournament info (dates, prize pool, format)
│   │   └── Current stage indicator
│   ├── Teams Tab
│   │   └── Grid of team cards with logos
│   └── Schedule Tab
│       ├── Date picker / day selector
│       └── Match list for selected day
```

---

## PHASE 2: FANTASY CORE (Weeks 5-8)

### Slice 4: Player Database

**Duration:** Week 5

**User Story:** As a user, I can browse players and see their basic info and statistics.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Player list screen, player card (photo, name, role, team), player detail screen, basic stats display, search/filter by role |
| **Backend** | Player model, `GET /players`, `GET /players/:id`, `GET /players/:id/stats` |
| **Database** | Player table, link to Team, average stats fields |
| **Integration** | STRATZ GraphQL integration for player stats |

**Acceptance Criteria:** User can browse all players, filter by role, and see player profile with stats.

**STRATZ Query Example:**
```graphql
query GetPlayerStats($steamId: Long!) {
  player(steamAccountId: $steamId) {
    steamAccountId
    proSteamAccount {
      name
      realName
      team {
        name
        tag
      }
      position
      countries
    }
    matchCount
    winCount
    performance {
      kills
      deaths
      assists
    }
  }
}
```

---

### Slice 5: Fantasy Team Creation

**Duration:** Weeks 6-7

**User Story:** As a user, I can create a fantasy team by selecting 5 players for a tournament.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Fantasy team creation wizard, player picker with role slots (Carry, Mid, Offlane, Sup4, Sup5), roster summary, validation (team diversity rules), save team |
| **Backend** | FantasyTeam model, FantasyRoster model, `POST /fantasy/teams`, `PUT /fantasy/teams/:id/roster`, roster validation logic |
| **Database** | FantasyTeam table, FantasyRoster table, constraints |

**Acceptance Criteria:** User can create fantasy team, select 5 players (one per role), designate captain, and save roster.

**Roster Rules:**
- Must have exactly 5 players (one per role)
- Maximum 2 players from same pro team (optional rule)
- Captain designation required
- Changes allowed until roster lock

**UI Flow:**
```
1. Select Tournament → 
2. Name Your Team → 
3. Pick Carry → 
4. Pick Mid → 
5. Pick Offlane → 
6. Pick Support 4 → 
7. Pick Support 5 → 
8. Choose Captain → 
9. Confirm & Save
```

---

### Slice 6: Fantasy Points Calculation

**Duration:** Week 8

**User Story:** As a user, I can see how many fantasy points my team earned from completed matches.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Fantasy team dashboard, points breakdown by player, points history chart, game-by-game detail |
| **Backend** | Points calculation service, PlayerStats model, FantasyPoints model, background job to calculate after match |
| **Database** | PlayerStats table, FantasyPoints table, Game table |
| **Integration** | STRATZ match data fetching, post-match processing job |

**Acceptance Criteria:** After a match completes, user sees points for each rostered player with breakdown.

**Points Calculation Service:**
```typescript
// services/fantasy-points.service.ts
interface PointsBreakdown {
  kills: number;
  deaths: number;
  assists: number;
  lastHits: number;
  gpm: number;
  xpm: number;
  towerDamage: number;
  heroDamage: number;
  heroHealing: number;
  stuns: number;
  obsPlaced: number;
  firstBlood: number;
  winBonus: number;
  subtotal: number;
  captainMultiplier: number;
  total: number;
}

function calculateFantasyPoints(stats: PlayerStats, isCaptain: boolean): PointsBreakdown {
  const breakdown = {
    kills: stats.kills * 0.3,
    deaths: stats.deaths * -0.3,
    assists: stats.assists * 0.15,
    lastHits: stats.lastHits * 0.003,
    gpm: stats.gpm * 0.002,
    xpm: stats.xpm * 0.001,
    towerDamage: stats.towerDamage * 0.001,
    heroDamage: stats.heroDamage * 0.0001,
    heroHealing: stats.heroHealing * 0.0002,
    stuns: stats.stuns * 0.05,
    obsPlaced: stats.obsPlaced * 0.25,
    firstBlood: stats.firstBlood ? 1.0 : 0,
    winBonus: stats.isWinner ? 3.0 : 0,
  };
  
  const subtotal = Object.values(breakdown).reduce((a, b) => a + b, 0);
  const multiplier = isCaptain ? 2 : 1;
  
  return {
    ...breakdown,
    subtotal,
    captainMultiplier: multiplier,
    total: subtotal * multiplier
  };
}
```

---

## PHASE 3: COMPETITION (Weeks 9-12)

### Slice 7: Fantasy Leagues & Leaderboards

**Duration:** Weeks 9-10

**User Story:** As a user, I can join/create leagues and compete against others on leaderboards.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Leagues list screen, create league form, join league (invite code), league detail with standings, global leaderboard |
| **Backend** | FantasyLeague model, LeagueMembership model, league CRUD endpoints, leaderboard calculation, invite code generation |
| **Database** | FantasyLeague table, LeagueMembership table, indexes for rankings |

**Acceptance Criteria:** User can create private league, invite friends via code, see standings updated after matches.

**League Types:**
- **Public Leagues**: Anyone can join, global competition
- **Private Leagues**: Invite-only, friend groups
- **Official Leagues**: Created by app, featured competitions

**Leaderboard Query:**
```sql
SELECT 
  ft.id,
  ft.name as team_name,
  u.username,
  u.avatar_url,
  ft.total_points,
  RANK() OVER (ORDER BY ft.total_points DESC) as rank
FROM fantasy_teams ft
JOIN users u ON ft.user_id = u.id
WHERE ft.league_id = $1
ORDER BY ft.total_points DESC
LIMIT 100;
```

---

### Slice 8: Notifications & Polish

**Duration:** Weeks 11-12

**User Story:** As a user, I receive notifications about matches and can enjoy a polished experience.

| Layer | Tasks |
|-------|-------|
| **Flutter App** | Push notification handling, notification preferences, UI polish, animations, empty states, onboarding flow |
| **Backend** | FCM integration, notification service, user preference storage, notification triggers (match start, match end, roster lock) |
| **Database** | NotificationPreference table, DeviceToken table |
| **Infra** | Production environment, App Store submission prep, TestFlight beta |

**Acceptance Criteria:** User receives push notifications, app is polished and ready for App Store submission.

**Notification Types:**
| Event | Title | Body | Timing |
|-------|-------|------|--------|
| Roster Lock Warning | "Lock your roster!" | "Rosters lock in 1 hour for [Tournament]" | 1 hour before |
| Match Starting | "Match Starting" | "[Team A] vs [Team B] is about to begin" | 5 min before |
| Match Completed | "Match Result" | "[Team A] defeats [Team B] 2-1. Check your points!" | After match |
| Points Updated | "Points Updated" | "You earned X points today. Current rank: #Y" | Daily summary |

---

## PHASE 4: LAUNCH (Weeks 13-14)

### Launch Preparation Checklist

#### App Store Requirements
- [ ] App icon (all sizes)
- [ ] Screenshots (6.7", 6.5", 5.5" iPhones, iPad)
- [ ] App preview video (optional but recommended)
- [ ] App description (short + full)
- [ ] Keywords for ASO
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support URL
- [ ] Age rating questionnaire
- [ ] App category selection

#### Technical Checklist
- [ ] Production environment deployed
- [ ] SSL certificates configured
- [ ] Database backups automated
- [ ] Monitoring and alerting active
- [ ] Error tracking (Sentry/Crashlytics)
- [ ] Analytics events defined
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Load testing completed

#### Pre-Launch Marketing
- [ ] Landing page live
- [ ] Social media accounts created
- [ ] Reddit /r/DotA2 post drafted
- [ ] Discord server set up
- [ ] Press kit prepared
- [ ] Beta tester feedback incorporated
- [ ] Launch day announcement ready

---

## 6. Post-MVP Roadmap

### Version 1.1 - Platform Expansion (Months 4-5)

- Android app release via Google Play Store
- Flutter Web deployment for browser access
- Performance optimizations based on user feedback
- Bug fixes from MVP launch

### Version 1.2 - Live Features (Months 5-6)

- Live match status integration (Steam API `GetLiveLeagueGames`)
- Real-time score updates via WebSockets
- Live fantasy point tracking during matches
- Match reminders and calendar integration (iOS/Android native)

### Version 1.3 - Social & Engagement (Months 6-8)

- In-app chat for leagues
- Achievement system and badges
- Seasonal rewards and rankings
- Share fantasy results to social media
- Friend system and head-to-head challenges
- Push notification improvements

### Version 2.0 - Monetization & Scale (Months 8-12)

- Premium subscription launch (Pro tier)
- In-app purchases for cosmetics
- Expanded tournament coverage (beyond DPC)
- Draft mode for leagues (snake draft, auction)
- Advanced analytics and predictions
- API for third-party integrations
- Localization (Chinese, Russian, Spanish)

---

## 7. Timeline Summary

| Phase | Duration | Slices | Key Deliverable |
|-------|----------|--------|-----------------|
| **1: Foundation** | Weeks 1-4 | 1-3: Setup, Auth, Tournaments | Tournament browser app |
| **2: Fantasy Core** | Weeks 5-8 | 4-6: Players, Fantasy, Points | Core fantasy system |
| **3: Competition** | Weeks 9-12 | 7-8: Leagues, Notifications | Competition features |
| **4: Launch** | Weeks 13-14 | Launch prep | App Store release |

**Total MVP Development Time: 14 weeks (3.5 months)**

### Gantt Chart

```
Week:  1   2   3   4   5   6   7   8   9  10  11  12  13  14
       ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
Slice 1 ███
Slice 2     ███
Slice 3         ███████
Slice 4                 ███
Slice 5                     ███████
Slice 6                             ███
Slice 7                                 ███████
Slice 8                                         ███████
Launch                                                  ███████
       └───────────────┴───────────────┴───────────────┴───────┘
         Phase 1           Phase 2          Phase 3      Phase 4
```

---

## 8. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Liquipedia API rate limits** | High | Medium | Aggressive caching, request batching, consider paid tier |
| **STRATZ API changes** | Medium | Low | Abstract API layer, monitor changelog, have OpenDota fallback |
| **DPC schedule changes** | Medium | Medium | Flexible tournament model, admin tools for manual updates |
| **App Store rejection** | High | Low | Follow guidelines strictly, no gambling features initially |
| **Low initial user adoption** | Medium | Medium | Community marketing, Reddit/Discord presence, content creators |
| **Valve policy changes** | Low | Low | Monitor Valve communications, stay compliant with terms |
| **Data accuracy issues** | Medium | Medium | Validation layer, user reporting, manual override capability |
| **Server scalability** | Medium | Low | Auto-scaling infrastructure, load testing before major tournaments |

### Contingency Plans

**If Liquipedia API becomes unavailable:**
1. Fall back to cached data (24h staleness acceptable for non-live data)
2. Implement manual data entry admin panel
3. Explore alternative sources (STRATZ has some tournament data)

**If STRATZ API becomes unavailable:**
1. Switch to OpenDota API (similar data, different format)
2. Delay points calculation until API restored
3. Communicate delays to users via in-app banner

---

## 9. Success Criteria

### 9.1 MVP Success Metrics (3 months post-launch)

| Metric | Target |
|--------|--------|
| Registered users | 1,000+ |
| Fantasy teams created | 500+ |
| Active leagues | 100+ |
| App Store rating | 4.0+ |
| Day-7 retention rate | 30%+ |
| Crash rate | < 1% |
| API uptime | 99.5%+ |

### 9.2 Year 1 Goals

| Metric | Target |
|--------|--------|
| Registered users | 50,000+ |
| Monthly active users (MAU) | 10,000+ |
| Free-to-paid conversion | 5%+ |
| DPC tournament coverage | 100% |
| Platforms | iOS + Android + Web |
| Revenue vs costs | Break-even |

### 9.3 Long-term Vision (Year 2-3)

- 250,000+ registered users
- Expand to other Valve esports (CS2)
- Official partnerships with tournament organizers
- Community-driven features (custom scoring, leagues)
- Sustainable profitable business

---

# Appendix A: API Integration Details

## A.1 Liquipedia Integration

**Purpose:** Tournament metadata, teams, players, schedules

**Base URL:** `https://liquipedia.net/dota2/api.php` (MediaWiki API)

**Authentication:** 
- User-Agent header required (identify your app)
- API key for LiquipediaDB (paid tier)

**Rate Limits:**
- MediaWiki API: 1 request per 2 seconds
- LiquipediaDB: 60 requests per hour (free tier)

**Data to Fetch:**
- Tournament list and details
- Team rosters
- Match schedules
- Group stage standings
- Playoff brackets

**Example Request:**
```bash
curl "https://liquipedia.net/dota2/api.php?action=parse&page=Dota_Pro_Circuit/2024/1/WEU/Division_I&format=json" \
  -H "User-Agent: Dota2FantasyApp/1.0 (contact@example.com)"
```

**Caching Strategy:**
| Data Type | Cache Duration | Refresh Trigger |
|-----------|----------------|-----------------|
| Tournament list | 1 hour | Manual or daily |
| Tournament details | 30 minutes | During tournament |
| Team rosters | 24 hours | Manual trigger |
| Match schedule | 15 minutes | During tournament |
| Results | 5 minutes | After match ends |

---

## A.2 STRATZ Integration

**Purpose:** Detailed match statistics for fantasy points

**Base URL:** `https://api.stratz.com/graphql`

**Authentication:** Bearer token from STRATZ account

**Rate Limits:** 
- Tier 1 (free with login): 2,000 requests/hour
- Tier 2 (individual): 4,000 requests/hour

**Data to Fetch:**
- Match details (after completion)
- Player performance stats
- Hero/item builds
- League information

### Sample GraphQL Queries

**Get Match Statistics:**
```graphql
query GetMatchStats($matchId: Long!) {
  match(id: $matchId) {
    id
    didRadiantWin
    durationSeconds
    league {
      id
      name
    }
    players {
      steamAccountId
      isRadiant
      heroId
      position
      kills
      deaths
      assists
      goldPerMinute
      experiencePerMinute
      heroDamage
      towerDamage
      heroHealing
      lastHits
      denies
      networth
      imp  # Individual Match Performance score
      stats {
        campStack
        heroDamageReport {
          dealtTotal {
            stunDuration
          }
        }
        wardDestruction {
          isWard
        }
      }
      item0Id
      item1Id
      item2Id
      item3Id
      item4Id
      item5Id
    }
  }
}
```

**Get League Matches:**
```graphql
query GetLeagueMatches($leagueId: Int!, $take: Int = 100) {
  league(id: $leagueId) {
    id
    displayName
    matches(request: { take: $take, orderBy: START_DATE_TIME }) {
      id
      startDateTime
      didRadiantWin
      radiantTeam {
        name
        tag
      }
      direTeam {
        name
        tag
      }
    }
  }
}
```

**Get Player Career Stats:**
```graphql
query GetPlayerStats($steamId: Long!) {
  player(steamAccountId: $steamId) {
    steamAccountId
    proSteamAccount {
      name
      realName
      team {
        name
        tag
        logo
      }
      position
      birthday
      countries
    }
    matchCount
    winCount
    performance {
      kills
      deaths
      assists
    }
    heroesPerformance {
      heroId
      matchCount
      winCount
      avgKills
      avgDeaths
      avgAssists
    }
  }
}
```

---

## A.3 Firebase Configuration

### Firebase Services Used

| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication (email, Google, Apple) |
| Cloud Messaging (FCM) | Push notifications |
| Analytics | User behavior tracking |
| Crashlytics | Crash reporting |
| Remote Config | Feature flags |

### FCM Notification Payload

```json
{
  "message": {
    "token": "device_fcm_token",
    "notification": {
      "title": "Match Starting Soon!",
      "body": "Team Spirit vs Tundra begins in 5 minutes"
    },
    "data": {
      "type": "match_starting",
      "matchId": "12345",
      "tournamentId": "67890"
    },
    "apns": {
      "payload": {
        "aps": {
          "badge": 1,
          "sound": "default"
        }
      }
    }
  }
}
```

---

## A.4 Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/dota2fantasy
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRY=7d

# External APIs
LIQUIPEDIA_API_KEY=your-liquipedia-key
STRATZ_API_TOKEN=your-stratz-token

# Firebase
FIREBASE_PROJECT_ID=dota2-fantasy
FIREBASE_PRIVATE_KEY=your-firebase-key
FIREBASE_CLIENT_EMAIL=firebase-admin@dota2-fantasy.iam.gserviceaccount.com

# App Config
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Feature Flags
ENABLE_LIVE_SCORES=false
ENABLE_PREMIUM=false
```

---

## A.5 Project Structure

### Flutter App Structure

```
flutter_app/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── api_endpoints.dart
│   │   ├── storage/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── tournaments/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── players/
│   │   ├── fantasy/
│   │   ├── leagues/
│   │   └── settings/
│   └── shared/
│       ├── widgets/
│       └── providers/
├── test/
├── pubspec.yaml
└── README.md
```

### Backend Structure

```
backend/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.module.ts
│   │   │   └── strategies/
│   │   ├── tournaments/
│   │   ├── players/
│   │   ├── matches/
│   │   ├── fantasy/
│   │   └── notifications/
│   ├── integrations/
│   │   ├── liquipedia/
│   │   │   ├── liquipedia.service.ts
│   │   │   └── liquipedia.types.ts
│   │   └── stratz/
│   │       ├── stratz.service.ts
│   │       └── stratz.queries.ts
│   ├── jobs/
│   │   ├── sync-tournaments.job.ts
│   │   ├── fetch-match-stats.job.ts
│   │   └── calculate-points.job.ts
│   ├── common/
│   │   ├── decorators/
│   │   ├── filters/
│   │   ├── guards/
│   │   └── interceptors/
│   └── config/
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── test/
├── docker-compose.yml
├── Dockerfile
└── package.json
```

---

**End of Document**

*Last Updated: January 2026*
*Document Version: 1.0*
