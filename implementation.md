# Dota 2 Fantasy Points - Implementation Guide

**Version 1.0 | January 2026**

This document serves as the development guide for the Dota 2 Fantasy Points application. It translates the plan into actionable implementation steps organized by vertical slices.

---

## Technology Decisions

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **State Management** | Riverpod 2.x | Compile-safe, excellent DI, modern approach |
| **Backend Framework** | NestJS | Structured, modules, guards, great TypeScript support |
| **Infrastructure** | Supabase | All-in-one (PostgreSQL, Auth, Realtime, Storage) |
| **Initial Platform** | iOS | Focus MVP on single platform, expand post-launch |

---

## Project Structure

### Repository Organization

```
dota-fantasy/
├── apps/
│   ├── mobile/              # Flutter mobile app
│   └── backend/             # NestJS backend
├── packages/
│   └── shared/              # Shared types/constants (future)
├── docs/
│   ├── plan.md
│   └── implementation.md
└── README.md
```

### Flutter App Structure (`apps/mobile/`)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                 # Root MaterialApp widget
│   ├── router.dart              # GoRouter configuration
│   └── theme.dart               # App theme definitions
├── core/
│   ├── constants/
│   │   ├── api_constants.dart   # API URLs, endpoints
│   │   └── app_constants.dart   # App-wide constants
│   ├── errors/
│   │   ├── exceptions.dart      # Custom exceptions
│   │   └── failures.dart        # Failure classes
│   ├── network/
│   │   ├── dio_client.dart      # Dio instance with interceptors
│   │   └── api_interceptor.dart # Auth token interceptor
│   ├── storage/
│   │   ├── secure_storage.dart  # Token storage
│   │   └── local_storage.dart   # Hive boxes
│   └── utils/
│       ├── date_utils.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── user.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── signup_screen.dart
│   │       └── widgets/
│   │           └── auth_form.dart
│   ├── tournaments/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── players/
│   ├── fantasy/
│   ├── leagues/
│   └── settings/
└── shared/
    ├── widgets/
    │   ├── loading_indicator.dart
    │   ├── error_widget.dart
    │   └── empty_state.dart
    └── providers/
        └── common_providers.dart
```

### Backend Structure (`apps/backend/`)

```
src/
├── main.ts
├── app.module.ts
├── modules/
│   ├── auth/
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── dto/
│   │   │   ├── login.dto.ts
│   │   │   └── register.dto.ts
│   │   ├── guards/
│   │   │   └── jwt-auth.guard.ts
│   │   └── strategies/
│   │       └── jwt.strategy.ts
│   ├── tournaments/
│   │   ├── tournaments.module.ts
│   │   ├── tournaments.controller.ts
│   │   └── tournaments.service.ts
│   ├── players/
│   ├── matches/
│   ├── fantasy/
│   └── notifications/
├── integrations/
│   ├── supabase/
│   │   └── supabase.service.ts
│   ├── liquipedia/
│   │   ├── liquipedia.service.ts
│   │   └── liquipedia.types.ts
│   └── stratz/
│       ├── stratz.service.ts
│       ├── stratz.queries.ts
│       └── stratz.types.ts
├── jobs/
│   ├── sync-tournaments.job.ts
│   ├── fetch-match-stats.job.ts
│   └── calculate-points.job.ts
├── common/
│   ├── decorators/
│   │   └── current-user.decorator.ts
│   ├── filters/
│   │   └── http-exception.filter.ts
│   ├── interceptors/
│   │   └── transform.interceptor.ts
│   └── dto/
│       └── pagination.dto.ts
└── config/
    ├── configuration.ts
    └── validation.ts
```

---

## Phase 1: Foundation

### Slice 1: Project Setup & Authentication

**Goal:** User can sign up, log in, and see their profile.

#### 1.1 Flutter Setup

**Tasks:**
- [ ] Create Flutter project with `flutter create --org com.dotafantasy mobile`
- [ ] Configure `pubspec.yaml` with dependencies
- [ ] Set up folder structure
- [ ] Configure Riverpod
- [ ] Set up GoRouter
- [ ] Create splash screen
- [ ] Build auth screens (login/signup)
- [ ] Integrate Supabase Auth

**Key Dependencies (`pubspec.yaml`):**
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Routing
  go_router: ^13.0.0

  # Network
  dio: ^5.4.0

  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0

  # Supabase
  supabase_flutter: ^2.3.0

  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

  # Utils
  intl: ^0.18.1
  equatable: ^2.0.5
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
```

**Auth Provider (`lib/features/auth/presentation/providers/auth_provider.dart`):**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  Stream<AuthState> build() {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String email, String password, String username) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.session?.user;
}
```

**Router Configuration (`lib/app/router.dart`):**
```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (user == null && !isAuthRoute) {
        return '/auth/login';
      }
      if (user != null && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // Tournament routes
      GoRoute(
        path: '/tournaments',
        builder: (context, state) => const TournamentListScreen(),
      ),
      GoRoute(
        path: '/tournaments/:id',
        builder: (context, state) => TournamentDetailScreen(
          id: state.pathParameters['id']!,
        ),
      ),
      // Add more routes as slices are implemented
    ],
  );
});
```

#### 1.2 Backend Setup

**Tasks:**
- [ ] Create NestJS project with `nest new backend`
- [ ] Configure Supabase connection
- [ ] Set up Prisma with Supabase PostgreSQL
- [ ] Create User module
- [ ] Implement JWT authentication (using Supabase JWT)
- [ ] Create auth endpoints
- [ ] Set up Docker for local development

**Supabase Database Schema (run in Supabase SQL Editor):**
```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users (extends Supabase auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    avatar_url VARCHAR(500),
    bio TEXT,
    favorite_team_id UUID,
    subscription_tier VARCHAR(20) DEFAULT 'free',
    subscription_expires TIMESTAMP,
    total_fantasy_points DECIMAL(12, 2) DEFAULT 0,
    tournaments_played INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User Settings
CREATE TABLE public.user_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN DEFAULT true,
    notify_match_start BOOLEAN DEFAULT true,
    notify_match_end BOOLEAN DEFAULT true,
    notify_roster_lock BOOLEAN DEFAULT true,
    theme VARCHAR(20) DEFAULT 'system',
    language VARCHAR(10) DEFAULT 'en'
);

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, username)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'username');

    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can view their own settings"
    ON public.user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
    ON public.user_settings FOR UPDATE
    USING (auth.uid() = user_id);
```

**NestJS Auth Module (`src/modules/auth/auth.service.ts`):**
```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

@Injectable()
export class AuthService {
  constructor(private supabase: SupabaseService) {}

  async validateToken(token: string) {
    const { data, error } = await this.supabase.client.auth.getUser(token);

    if (error || !data.user) {
      throw new UnauthorizedException('Invalid token');
    }

    return data.user;
  }

  async getProfile(userId: string) {
    const { data, error } = await this.supabase.client
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) throw error;
    return data;
  }

  async updateProfile(userId: string, updates: Partial<UserProfile>) {
    const { data, error } = await this.supabase.client
      .from('user_profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}
```

**API Endpoints:**
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/auth/me` | Get current user profile |
| PUT | `/api/v1/auth/profile` | Update user profile |
| GET | `/api/v1/auth/settings` | Get user settings |
| PUT | `/api/v1/auth/settings` | Update user settings |

**Acceptance Criteria:**
- [ ] User can sign up with email and password
- [ ] User can log in with existing credentials
- [ ] User sees their profile after login
- [ ] JWT tokens are properly stored and refreshed
- [ ] Unauthorized requests are rejected

---

### Slice 2: Tournament List

**Goal:** User can see a list of upcoming and ongoing DPC tournaments.

#### 2.1 Database Schema

```sql
-- Tournaments
CREATE TABLE public.tournaments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    tier VARCHAR(20) NOT NULL,  -- 'tier1', 'tier2', 'tier3', 'major', 'ti'
    start_date DATE NOT NULL,
    end_date DATE,
    prize_pool DECIMAL(12, 2),
    format TEXT,
    liquipedia_url VARCHAR(500),
    logo_url VARCHAR(500),
    status VARCHAR(20) DEFAULT 'upcoming',  -- 'upcoming', 'ongoing', 'completed'
    region VARCHAR(50),  -- 'NA', 'SA', 'WEU', 'EEU', 'CN', 'SEA'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for common queries
CREATE INDEX idx_tournaments_status ON public.tournaments(status);
CREATE INDEX idx_tournaments_tier ON public.tournaments(tier);
CREATE INDEX idx_tournaments_start_date ON public.tournaments(start_date);

-- RLS Policies (tournaments are publicly viewable)
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tournaments are viewable by everyone"
    ON public.tournaments FOR SELECT
    USING (true);
```

#### 2.2 Backend Implementation

**Tournament Service (`src/modules/tournaments/tournaments.service.ts`):**
```typescript
import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

export interface TournamentFilters {
  status?: 'upcoming' | 'ongoing' | 'completed';
  tier?: string;
  region?: string;
}

@Injectable()
export class TournamentsService {
  constructor(private supabase: SupabaseService) {}

  async findAll(filters: TournamentFilters = {}, page = 1, limit = 20) {
    let query = this.supabase.client
      .from('tournaments')
      .select('*', { count: 'exact' });

    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.tier) {
      query = query.eq('tier', filters.tier);
    }
    if (filters.region) {
      query = query.eq('region', filters.region);
    }

    const { data, error, count } = await query
      .order('start_date', { ascending: true })
      .range((page - 1) * limit, page * limit - 1);

    if (error) throw error;

    return {
      data,
      meta: {
        page,
        limit,
        total: count,
      },
    };
  }

  async findOne(id: string) {
    const { data, error } = await this.supabase.client
      .from('tournaments')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  }
}
```

**Tournament Controller (`src/modules/tournaments/tournaments.controller.ts`):**
```typescript
import { Controller, Get, Param, Query } from '@nestjs/common';
import { TournamentsService, TournamentFilters } from './tournaments.service';
import { Public } from '../auth/decorators/public.decorator';

@Controller('api/v1/tournaments')
export class TournamentsController {
  constructor(private tournamentsService: TournamentsService) {}

  @Public()
  @Get()
  async findAll(
    @Query('status') status?: string,
    @Query('tier') tier?: string,
    @Query('region') region?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    const filters: TournamentFilters = { status, tier, region };
    return this.tournamentsService.findAll(filters, +page, +limit);
  }

  @Public()
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.tournamentsService.findOne(id);
  }
}
```

#### 2.3 Flutter Implementation

**Tournament Model (`lib/features/tournaments/data/models/tournament_model.dart`):**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

@freezed
class Tournament with _$Tournament {
  const factory Tournament({
    required String id,
    required String name,
    required String tier,
    required DateTime startDate,
    DateTime? endDate,
    double? prizePool,
    String? format,
    String? liquipediaUrl,
    String? logoUrl,
    required String status,
    String? region,
  }) = _Tournament;

  factory Tournament.fromJson(Map<String, dynamic> json) =>
      _$TournamentFromJson(json);
}
```

**Tournament Repository (`lib/features/tournaments/data/tournament_repository.dart`):**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import 'models/tournament_model.dart';

part 'tournament_repository.g.dart';

@riverpod
TournamentRepository tournamentRepository(TournamentRepositoryRef ref) {
  return TournamentRepository(ref.read(dioClientProvider));
}

class TournamentRepository {
  final DioClient _client;

  TournamentRepository(this._client);

  Future<List<Tournament>> getTournaments({
    String? status,
    String? tier,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '/tournaments',
      queryParameters: {
        if (status != null) 'status': status,
        if (tier != null) 'tier': tier,
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data['data'] as List;
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  Future<Tournament> getTournament(String id) async {
    final response = await _client.get('/tournaments/$id');
    return Tournament.fromJson(response.data['data']);
  }
}
```

**Tournament List Provider (`lib/features/tournaments/presentation/providers/tournament_list_provider.dart`):**
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/tournament_repository.dart';
import '../../data/models/tournament_model.dart';

part 'tournament_list_provider.g.dart';

@riverpod
Future<List<Tournament>> tournamentList(
  TournamentListRef ref, {
  String? status,
  String? tier,
}) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getTournaments(status: status, tier: tier);
}

@riverpod
Future<Tournament> tournamentDetail(TournamentDetailRef ref, String id) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getTournament(id);
}
```

**Tournament List Screen (`lib/features/tournaments/presentation/screens/tournament_list_screen.dart`):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tournament_list_provider.dart';
import '../widgets/tournament_card.dart';

class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentListProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tournamentListProvider().future),
        child: tournamentsAsync.when(
          data: (tournaments) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              return TournamentCard(tournament: tournaments[index]);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                ElevatedButton(
                  onPressed: () => ref.refresh(tournamentListProvider()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Tournament Card Widget (`lib/features/tournaments/presentation/widgets/tournament_card.dart`):**
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/tournament_model.dart';
import 'tier_badge.dart';
import 'status_chip.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/tournaments/${tournament.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tournament logo placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: tournament.logoUrl != null
                    ? Image.network(tournament.logoUrl!)
                    : const Icon(Icons.emoji_events),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tournament.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TierBadge(tier: tournament.tier),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateRange(tournament.startDate, tournament.endDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(status: tournament.status),
                        if (tournament.prizePool != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${tournament.prizePool!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final startStr = '${start.month}/${start.day}/${start.year}';
    if (end == null) return startStr;
    final endStr = '${end.month}/${end.day}/${end.year}';
    return '$startStr - $endStr';
  }
}
```

**Acceptance Criteria:**
- [ ] User sees list of tournaments sorted by start date
- [ ] Each tournament shows name, tier badge, dates, status
- [ ] Pull-to-refresh updates the list
- [ ] Loading state displays while fetching
- [ ] Error state with retry button on failure
- [ ] Tapping a tournament navigates to detail screen

---

### Slice 3: Tournament Details

**Goal:** User can view tournament details including teams, format, and schedule.

#### 3.1 Database Schema

```sql
-- Teams
CREATE TABLE public.teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    tag VARCHAR(10),
    logo_url VARCHAR(500),
    region VARCHAR(50),
    liquipedia_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tournament Teams (junction table)
CREATE TABLE public.tournament_teams (
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    seed INTEGER,
    group_name VARCHAR(50),
    PRIMARY KEY (tournament_id, team_id)
);

-- Matches
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
    team1_id UUID REFERENCES public.teams(id),
    team2_id UUID REFERENCES public.teams(id),
    scheduled_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'live', 'completed'
    winner_id UUID REFERENCES public.teams(id),
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    best_of INTEGER DEFAULT 3,
    stage VARCHAR(100),  -- 'group_a', 'playoffs', 'grand_final'
    stream_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Games (individual games within a match/series)
CREATE TABLE public.games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    game_number INTEGER NOT NULL,
    radiant_team_id UUID REFERENCES public.teams(id),
    dire_team_id UUID REFERENCES public.teams(id),
    winner_id UUID REFERENCES public.teams(id),
    duration INTEGER,  -- seconds
    stratz_match_id BIGINT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_matches_tournament ON public.matches(tournament_id);
CREATE INDEX idx_matches_status ON public.matches(status);
CREATE INDEX idx_matches_scheduled ON public.matches(scheduled_at);
CREATE INDEX idx_games_match ON public.games(match_id);

-- RLS
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teams are viewable by everyone" ON public.teams FOR SELECT USING (true);
CREATE POLICY "Tournament teams are viewable by everyone" ON public.tournament_teams FOR SELECT USING (true);
CREATE POLICY "Matches are viewable by everyone" ON public.matches FOR SELECT USING (true);
CREATE POLICY "Games are viewable by everyone" ON public.games FOR SELECT USING (true);
```

#### 3.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments/:id/teams` | Get teams in tournament |
| GET | `/api/v1/tournaments/:id/matches` | Get matches for tournament |
| GET | `/api/v1/tournaments/:id/standings` | Get group standings |
| GET | `/api/v1/matches/:id` | Get match details |
| GET | `/api/v1/matches/:id/games` | Get games in a match |

#### 3.3 Flutter Implementation

**Tournament Detail Screen (`lib/features/tournaments/presentation/screens/tournament_detail_screen.dart`):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tournament_detail_provider.dart';
import '../widgets/tournament_overview_tab.dart';
import '../widgets/tournament_teams_tab.dart';
import '../widgets/tournament_schedule_tab.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String id;

  const TournamentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(id));

    return tournamentAsync.when(
      data: (tournament) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tournament.name),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Teams'),
                Tab(text: 'Schedule'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              TournamentOverviewTab(tournament: tournament),
              TournamentTeamsTab(tournamentId: id),
              TournamentScheduleTab(tournamentId: id),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

**Acceptance Criteria:**
- [ ] Tournament detail screen with 3 tabs (Overview, Teams, Schedule)
- [ ] Overview shows tournament info (dates, prize pool, format, current stage)
- [ ] Teams tab shows grid of participating teams with logos
- [ ] Schedule tab shows matches grouped by day
- [ ] Match cards show teams, time, score (if completed), and status

---

## Phase 2: Fantasy Core

### Slice 4: Player Database

**Goal:** User can browse players and see their basic info and statistics.

#### 4.1 Database Schema

```sql
-- Players
CREATE TABLE public.players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nickname VARCHAR(100) NOT NULL,
    real_name VARCHAR(255),
    role VARCHAR(20),  -- 'carry', 'mid', 'offlane', 'support4', 'support5'
    team_id UUID REFERENCES public.teams(id),
    country VARCHAR(100),
    avatar_url VARCHAR(500),
    stratz_id BIGINT UNIQUE,
    steam_id BIGINT UNIQUE,
    -- Cached stats (updated periodically)
    avg_kills DECIMAL(5, 2),
    avg_deaths DECIMAL(5, 2),
    avg_assists DECIMAL(5, 2),
    avg_gpm DECIMAL(7, 2),
    avg_fantasy_points DECIMAL(7, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX idx_players_team ON public.players(team_id);
CREATE INDEX idx_players_role ON public.players(role);
CREATE INDEX idx_players_stratz ON public.players(stratz_id);

-- RLS
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Players are viewable by everyone" ON public.players FOR SELECT USING (true);
```

#### 4.2 STRATZ Integration

**STRATZ Service (`src/integrations/stratz/stratz.service.ts`):**
```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class StratzService {
  private readonly apiUrl = 'https://api.stratz.com/graphql';
  private readonly token: string;

  constructor(private config: ConfigService) {
    this.token = this.config.get('STRATZ_API_TOKEN');
  }

  async getPlayerStats(steamId: number) {
    const query = `
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
    `;

    const response = await fetch(this.apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`,
      },
      body: JSON.stringify({
        query,
        variables: { steamId },
      }),
    });

    const data = await response.json();
    return data.data.player;
  }

  async getMatchStats(matchId: number) {
    const query = `
      query GetMatchStats($matchId: Long!) {
        match(id: $matchId) {
          id
          didRadiantWin
          durationSeconds
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
            stats {
              campStack
              heroDamageReport {
                dealtTotal {
                  stunDuration
                }
              }
            }
          }
        }
      }
    `;

    const response = await fetch(this.apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`,
      },
      body: JSON.stringify({
        query,
        variables: { matchId },
      }),
    });

    const data = await response.json();
    return data.data.match;
  }
}
```

#### 4.3 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/players` | List players (filterable by team, role) |
| GET | `/api/v1/players/:id` | Player details |
| GET | `/api/v1/players/:id/stats` | Player statistics |
| GET | `/api/v1/players/:id/fantasy-avg` | Average fantasy points |

**Acceptance Criteria:**
- [ ] User can browse all players
- [ ] Filter players by role (Carry, Mid, Offlane, Support 4, Support 5)
- [ ] Search players by name
- [ ] Player card shows photo, name, role, team, and avg fantasy points
- [ ] Player detail screen shows full stats

---

### Slice 5: Fantasy Team Creation

**Goal:** User can create a fantasy team by selecting 5 players for a tournament.

#### 5.1 Database Schema

```sql
-- Fantasy Leagues
CREATE TABLE public.fantasy_leagues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT true,
    max_members INTEGER DEFAULT 100,
    invite_code VARCHAR(20) UNIQUE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Fantasy Teams
CREATE TABLE public.fantasy_teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    league_id UUID REFERENCES public.fantasy_leagues(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    total_points DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, league_id)
);

-- Fantasy Rosters
CREATE TABLE public.fantasy_rosters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fantasy_team_id UUID REFERENCES public.fantasy_teams(id) ON DELETE CASCADE,
    player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
    slot VARCHAR(20) NOT NULL,  -- 'carry', 'mid', 'offlane', 'support4', 'support5'
    is_captain BOOLEAN DEFAULT false,
    locked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(fantasy_team_id, slot)
);

-- Indexes
CREATE INDEX idx_fantasy_leagues_tournament ON public.fantasy_leagues(tournament_id);
CREATE INDEX idx_fantasy_leagues_owner ON public.fantasy_leagues(owner_id);
CREATE INDEX idx_fantasy_teams_user ON public.fantasy_teams(user_id);
CREATE INDEX idx_fantasy_teams_league ON public.fantasy_teams(league_id);
CREATE INDEX idx_fantasy_rosters_team ON public.fantasy_rosters(fantasy_team_id);

-- RLS
ALTER TABLE public.fantasy_leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fantasy_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fantasy_rosters ENABLE ROW LEVEL SECURITY;

-- Users can view public leagues or leagues they're members of
CREATE POLICY "View leagues" ON public.fantasy_leagues FOR SELECT
USING (is_public = true OR owner_id = auth.uid());

-- Users can create leagues
CREATE POLICY "Create leagues" ON public.fantasy_leagues FOR INSERT
WITH CHECK (owner_id = auth.uid());

-- Users can view their own fantasy teams
CREATE POLICY "View own fantasy teams" ON public.fantasy_teams FOR SELECT
USING (user_id = auth.uid());

-- Users can create fantasy teams
CREATE POLICY "Create fantasy teams" ON public.fantasy_teams FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can update their own fantasy teams
CREATE POLICY "Update own fantasy teams" ON public.fantasy_teams FOR UPDATE
USING (user_id = auth.uid());

-- Roster policies
CREATE POLICY "View own rosters" ON public.fantasy_rosters FOR SELECT
USING (fantasy_team_id IN (SELECT id FROM public.fantasy_teams WHERE user_id = auth.uid()));

CREATE POLICY "Manage own rosters" ON public.fantasy_rosters FOR ALL
USING (fantasy_team_id IN (SELECT id FROM public.fantasy_teams WHERE user_id = auth.uid()));
```

#### 5.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/fantasy/teams` | Get user's fantasy teams |
| POST | `/api/v1/fantasy/teams` | Create fantasy team |
| GET | `/api/v1/fantasy/teams/:id` | Get fantasy team details |
| PUT | `/api/v1/fantasy/teams/:id/roster` | Update roster |
| POST | `/api/v1/fantasy/teams/:id/captain` | Set captain |

#### 5.3 Roster Validation

```typescript
// src/modules/fantasy/fantasy.service.ts

interface RosterSlot {
  slot: 'carry' | 'mid' | 'offlane' | 'support4' | 'support5';
  playerId: string;
}

async validateRoster(roster: RosterSlot[], tournamentId: string): Promise<ValidationResult> {
  const errors: string[] = [];

  // Check all 5 slots are filled
  const requiredSlots = ['carry', 'mid', 'offlane', 'support4', 'support5'];
  const filledSlots = roster.map(r => r.slot);
  const missingSlots = requiredSlots.filter(s => !filledSlots.includes(s));

  if (missingSlots.length > 0) {
    errors.push(`Missing slots: ${missingSlots.join(', ')}`);
  }

  // Check players are in the tournament
  const playerIds = roster.map(r => r.playerId);
  const tournamentPlayers = await this.getTournamentPlayers(tournamentId);
  const validPlayerIds = tournamentPlayers.map(p => p.id);

  for (const playerId of playerIds) {
    if (!validPlayerIds.includes(playerId)) {
      errors.push(`Player ${playerId} is not in this tournament`);
    }
  }

  // Optional: Max 2 players from same team
  const playersByTeam = new Map<string, number>();
  for (const playerId of playerIds) {
    const player = tournamentPlayers.find(p => p.id === playerId);
    if (player?.team_id) {
      const count = playersByTeam.get(player.team_id) || 0;
      playersByTeam.set(player.team_id, count + 1);
    }
  }

  for (const [teamId, count] of playersByTeam) {
    if (count > 2) {
      errors.push(`Cannot have more than 2 players from the same team`);
      break;
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
```

**Acceptance Criteria:**
- [ ] User can create a new fantasy team for a tournament
- [ ] Fantasy team creation wizard guides through player selection
- [ ] Each role slot can only have one player
- [ ] User must select exactly 5 players (one per role)
- [ ] User can designate a captain (2x points)
- [ ] Validation prevents invalid rosters
- [ ] User can edit roster until lock time

---

### Slice 6: Fantasy Points Calculation

**Goal:** User can see fantasy points earned from completed matches.

#### 6.1 Database Schema

```sql
-- Player Stats (per game)
CREATE TABLE public.player_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
    game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
    kills INTEGER DEFAULT 0,
    deaths INTEGER DEFAULT 0,
    assists INTEGER DEFAULT 0,
    last_hits INTEGER DEFAULT 0,
    denies INTEGER DEFAULT 0,
    gpm INTEGER DEFAULT 0,
    xpm INTEGER DEFAULT 0,
    hero_damage INTEGER DEFAULT 0,
    tower_damage INTEGER DEFAULT 0,
    hero_healing INTEGER DEFAULT 0,
    stuns DECIMAL(8, 2) DEFAULT 0,
    obs_placed INTEGER DEFAULT 0,
    camps_stacked INTEGER DEFAULT 0,
    first_blood BOOLEAN DEFAULT false,
    hero_id INTEGER,
    is_winner BOOLEAN DEFAULT false,
    raw_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(player_id, game_id)
);

-- Fantasy Points
CREATE TABLE public.fantasy_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    roster_id UUID REFERENCES public.fantasy_rosters(id) ON DELETE CASCADE,
    game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
    points DECIMAL(10, 2) NOT NULL,
    breakdown JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(roster_id, game_id)
);

-- Indexes
CREATE INDEX idx_player_stats_player ON public.player_stats(player_id);
CREATE INDEX idx_player_stats_game ON public.player_stats(game_id);
CREATE INDEX idx_fantasy_points_roster ON public.fantasy_points(roster_id);
CREATE INDEX idx_fantasy_points_game ON public.fantasy_points(game_id);

-- RLS
ALTER TABLE public.player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fantasy_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Player stats are viewable by everyone" ON public.player_stats FOR SELECT USING (true);
CREATE POLICY "Fantasy points viewable by team owner" ON public.fantasy_points FOR SELECT
USING (roster_id IN (
    SELECT fr.id FROM public.fantasy_rosters fr
    JOIN public.fantasy_teams ft ON fr.fantasy_team_id = ft.id
    WHERE ft.user_id = auth.uid()
));
```

#### 6.2 Points Calculation Service

```typescript
// src/modules/fantasy/services/points-calculator.service.ts

export interface PointsBreakdown {
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
  campsStacked: number;
  firstBlood: number;
  winBonus: number;
  subtotal: number;
  captainMultiplier: number;
  total: number;
}

const SCORING_RULES = {
  kills: 0.3,
  deaths: -0.3,
  assists: 0.15,
  lastHits: 0.003,
  denies: 0.003,
  gpm: 0.002,
  xpm: 0.001,
  towerDamage: 0.001,
  heroDamage: 0.0001,
  heroHealing: 0.0002,
  stuns: 0.05,
  obsPlaced: 0.25,
  campsStacked: 0.3,
  firstBlood: 1.0,
  winBonus: 3.0,
};

@Injectable()
export class PointsCalculatorService {
  calculatePoints(stats: PlayerStats, isCaptain: boolean): PointsBreakdown {
    const breakdown = {
      kills: stats.kills * SCORING_RULES.kills,
      deaths: stats.deaths * SCORING_RULES.deaths,
      assists: stats.assists * SCORING_RULES.assists,
      lastHits: stats.last_hits * SCORING_RULES.lastHits,
      gpm: stats.gpm * SCORING_RULES.gpm,
      xpm: stats.xpm * SCORING_RULES.xpm,
      towerDamage: stats.tower_damage * SCORING_RULES.towerDamage,
      heroDamage: stats.hero_damage * SCORING_RULES.heroDamage,
      heroHealing: stats.hero_healing * SCORING_RULES.heroHealing,
      stuns: stats.stuns * SCORING_RULES.stuns,
      obsPlaced: stats.obs_placed * SCORING_RULES.obsPlaced,
      campsStacked: stats.camps_stacked * SCORING_RULES.campsStacked,
      firstBlood: stats.first_blood ? SCORING_RULES.firstBlood : 0,
      winBonus: stats.is_winner ? SCORING_RULES.winBonus : 0,
    };

    const subtotal = Object.values(breakdown).reduce((a, b) => a + b, 0);
    const multiplier = isCaptain ? 2 : 1;

    return {
      ...breakdown,
      subtotal,
      captainMultiplier: multiplier,
      total: subtotal * multiplier,
    };
  }

  async processMatchCompletion(matchId: string) {
    // 1. Get all games for the match
    const games = await this.getMatchGames(matchId);

    // 2. For each game, fetch stats from STRATZ
    for (const game of games) {
      if (!game.stratz_match_id) continue;

      const stratzData = await this.stratz.getMatchStats(game.stratz_match_id);

      // 3. Save player stats
      for (const playerData of stratzData.players) {
        await this.savePlayerStats(game.id, playerData);
      }
    }

    // 4. Calculate fantasy points for all rosters
    await this.calculateFantasyPointsForMatch(matchId);

    // 5. Update total points for fantasy teams
    await this.updateFantasyTeamTotals(matchId);
  }
}
```

#### 6.3 Background Job

```typescript
// src/jobs/calculate-points.job.ts

import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class CalculatePointsJob {
  constructor(
    private pointsCalculator: PointsCalculatorService,
    private matchService: MatchService,
  ) {}

  // Run every 5 minutes to check for completed matches
  @Cron(CronExpression.EVERY_5_MINUTES)
  async handleCompletedMatches() {
    const completedMatches = await this.matchService.findRecentlyCompleted();

    for (const match of completedMatches) {
      try {
        await this.pointsCalculator.processMatchCompletion(match.id);
        console.log(`Processed points for match ${match.id}`);
      } catch (error) {
        console.error(`Failed to process match ${match.id}:`, error);
      }
    }
  }
}
```

**Acceptance Criteria:**
- [ ] After match completion, player stats are fetched from STRATZ
- [ ] Fantasy points are calculated using the scoring rules
- [ ] Points are stored with full breakdown
- [ ] Captain multiplier (2x) is applied correctly
- [ ] User can see points breakdown per game
- [ ] Fantasy team total points are updated
- [ ] Points display includes all stat categories

---

## Phase 3: Competition

### Slice 7: Fantasy Leagues & Leaderboards

**Goal:** User can join/create leagues and compete on leaderboards.

#### 7.1 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/fantasy/leagues` | Get user's leagues |
| POST | `/api/v1/fantasy/leagues` | Create new league |
| GET | `/api/v1/fantasy/leagues/:id` | League details |
| POST | `/api/v1/fantasy/leagues/:id/join` | Join with invite code |
| GET | `/api/v1/fantasy/leagues/:id/leaderboard` | League standings |
| GET | `/api/v1/leaderboard/global` | Global leaderboard |

#### 7.2 Leaderboard Query

```sql
-- League leaderboard
SELECT
    ft.id,
    ft.name as team_name,
    up.username,
    up.avatar_url,
    ft.total_points,
    RANK() OVER (ORDER BY ft.total_points DESC) as rank
FROM public.fantasy_teams ft
JOIN public.user_profiles up ON ft.user_id = up.id
WHERE ft.league_id = $1
ORDER BY ft.total_points DESC
LIMIT 100;

-- Global leaderboard (for a tournament)
SELECT
    ft.id,
    ft.name as team_name,
    up.username,
    up.avatar_url,
    ft.total_points,
    fl.name as league_name,
    RANK() OVER (ORDER BY ft.total_points DESC) as rank
FROM public.fantasy_teams ft
JOIN public.user_profiles up ON ft.user_id = up.id
JOIN public.fantasy_leagues fl ON ft.league_id = fl.id
WHERE fl.tournament_id = $1
ORDER BY ft.total_points DESC
LIMIT 100;
```

#### 7.3 Invite Code Generation

```typescript
// Generate unique invite code
function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing characters
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}
```

**Acceptance Criteria:**
- [ ] User can create private league with custom name
- [ ] User receives unique invite code for their league
- [ ] Other users can join using invite code
- [ ] League shows leaderboard of all members
- [ ] Global leaderboard shows top players across all leagues
- [ ] Leaderboard updates after points calculation
- [ ] User's rank and points are highlighted

---

### Slice 8: Notifications & Polish

**Goal:** User receives notifications and enjoys a polished experience.

#### 8.1 Push Notifications Setup

**Database:**
```sql
-- Device Tokens
CREATE TABLE public.device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20),  -- 'ios', 'android', 'web'
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, token)
);
```

**Notification Types:**
| Event | Title | Timing |
|-------|-------|--------|
| Roster Lock Warning | "Lock your roster!" | 1 hour before |
| Match Starting | "Match Starting" | 5 min before |
| Match Completed | "Match Result" | After match |
| Points Updated | "Points Updated" | Daily summary |

#### 8.2 Polish Tasks

**UI/UX:**
- [ ] Loading skeletons (shimmer effect)
- [ ] Empty states with illustrations
- [ ] Error states with retry
- [ ] Pull-to-refresh everywhere
- [ ] Smooth transitions and animations
- [ ] App icon and splash screen
- [ ] Onboarding flow (3-4 screens)

**Technical:**
- [ ] Offline data caching with Hive
- [ ] Image caching with CachedNetworkImage
- [ ] Error tracking with Firebase Crashlytics
- [ ] Analytics events for key actions
- [ ] Deep linking support

**Acceptance Criteria:**
- [ ] User receives push notifications for enabled events
- [ ] Notification preferences are respected
- [ ] App has polished loading/empty/error states
- [ ] Onboarding explains core features
- [ ] App works offline (cached data)
- [ ] No crashes, smooth performance

---

## Phase 4: Launch Preparation

### App Store Checklist

**Required Assets:**
- [ ] App icon (1024x1024)
- [ ] Screenshots for all required sizes
- [ ] App preview video (optional)
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support URL/email

**Metadata:**
- [ ] App name
- [ ] Subtitle
- [ ] Description (short + full)
- [ ] Keywords
- [ ] Category selection
- [ ] Age rating

### Technical Checklist

- [ ] Production Supabase project configured
- [ ] Environment variables set
- [ ] Database indexes optimized
- [ ] Rate limiting configured
- [ ] Error monitoring active
- [ ] Backup strategy in place
- [ ] Load testing completed

### Pre-Launch Marketing

- [ ] Landing page
- [ ] Social media accounts (Twitter/X, Discord)
- [ ] Beta testing via TestFlight
- [ ] Community outreach (Reddit, Discord servers)

---

## Development Workflow

### Git Branching Strategy

```
main (production)
  └── develop (staging)
        ├── feature/slice-1-auth
        ├── feature/slice-2-tournaments
        └── fix/tournament-loading
```

### Commit Convention

```
feat(auth): add login screen
fix(tournaments): correct date formatting
chore(deps): update flutter dependencies
docs(readme): add setup instructions
```

### Sprint Structure (per slice)

1. **Day 1-2:** Database schema + API endpoints
2. **Day 3-4:** Flutter UI + state management
3. **Day 5:** Integration testing + bug fixes
4. **Day 6:** Code review + refinements
5. **Day 7:** Documentation + merge

---

## Environment Setup

### Required Accounts

- [ ] Supabase project (free tier)
- [ ] STRATZ account (API token)
- [ ] Apple Developer account ($99/year)
- [ ] Firebase project (free tier)

### Environment Variables

```env
# Backend (.env)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key
STRATZ_API_TOKEN=your-stratz-token
JWT_SECRET=your-jwt-secret

# Flutter
# Create lib/core/constants/env.dart with:
# const supabaseUrl = 'https://xxx.supabase.co';
# const supabaseAnonKey = 'your-anon-key';
```

---

## Quick Reference

### Scoring Rules

| Stat | Points |
|------|--------|
| Kill | +0.3 |
| Death | -0.3 |
| Assist | +0.15 |
| Last Hit | +0.003 |
| GPM | +0.002 |
| XPM | +0.001 |
| Tower Damage | +0.001 |
| Hero Damage | +0.0001 |
| Hero Healing | +0.0002 |
| Stuns (sec) | +0.05 |
| Observer Ward | +0.25 |
| Camp Stack | +0.3 |
| First Blood | +1.0 |
| Win Bonus | +3.0 |
| **Captain** | **2x** |

### Player Roles

| Slot | Role |
|------|------|
| Position 1 | Carry |
| Position 2 | Mid |
| Position 3 | Offlane |
| Position 4 | Support (Soft) |
| Position 5 | Support (Hard) |

---

**Document Version:** 1.0
**Last Updated:** January 2026
