# Dota 2 Fantasy Points

A mobile application for Dota 2 fantasy sports, allowing users to create fantasy teams using professional Dota 2 players and compete in leagues during DPC tournaments.

## Project Structure

```
dota-fantasy/
├── apps/
│   ├── mobile/              # Flutter mobile app
│   │   ├── lib/
│   │   │   ├── app/         # App configuration (router, theme)
│   │   │   ├── core/        # Core utilities, network, storage
│   │   │   ├── features/    # Feature modules (auth, tournaments, etc.)
│   │   │   └── shared/      # Shared widgets and providers
│   │   └── pubspec.yaml
│   └── backend/             # NestJS backend
│       ├── src/
│       │   ├── modules/     # Feature modules (auth, tournaments, etc.)
│       │   ├── integrations/ # External API integrations
│       │   └── common/      # Shared utilities
│       └── package.json
├── docs/
│   ├── plan.md              # Business & Technical Plan
│   └── implementation.md    # Development Implementation Guide
├── docker-compose.yml       # Local development setup
└── README.md
```

## Technology Stack

### Mobile App
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod 2.x
- **Navigation:** GoRouter
- **Backend Auth:** Supabase
- **HTTP Client:** Dio

### Backend
- **Runtime:** Node.js 20 LTS
- **Framework:** NestJS
- **Database:** PostgreSQL (Supabase)
- **Authentication:** JWT (Supabase Auth)

## Getting Started

### Prerequisites

1. Flutter SDK (>= 3.2.0)
2. Node.js (>= 20 LTS)
3. Docker & Docker Compose
4. Supabase account
5. STRATZ API token

### Setup

1. **Clone the repository**

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase and API credentials
   ```

3. **Set up Supabase**
   - Create a new Supabase project
   - Run the SQL migrations from `docs/implementation.md` in the SQL editor
   - Copy your project URL and keys to `.env`

4. **Start the backend**
   ```bash
   cd apps/backend
   npm install
   npm run start:dev
   ```

5. **Run the mobile app**
   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```

   Or with Docker:
   ```bash
   docker-compose up -d
   ```

### Mobile App Configuration

Update the Supabase credentials in `apps/mobile/lib/core/constants/env.dart`:

```dart
class Env {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
}
```

## Development Slices

This project follows a vertical slice architecture. Here's the status:

- [x] **Slice 1:** Project Setup & Authentication
- [ ] **Slice 2:** Tournament List
- [ ] **Slice 3:** Tournament Details
- [ ] **Slice 4:** Player Database
- [ ] **Slice 5:** Fantasy Team Creation
- [ ] **Slice 6:** Fantasy Points Calculation
- [ ] **Slice 7:** Fantasy Leagues & Leaderboards
- [ ] **Slice 8:** Notifications & Polish

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/auth/me` | Get current user profile |
| PUT | `/api/v1/auth/profile` | Update user profile |
| GET | `/api/v1/auth/settings` | Get user settings |
| PUT | `/api/v1/auth/settings` | Update user settings |

### Tournaments (Coming in Slice 2)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments` | List tournaments |
| GET | `/api/v1/tournaments/:id` | Tournament details |

## License

MIT
