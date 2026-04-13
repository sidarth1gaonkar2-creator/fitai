
# Global Claude Instructions


These rules apply to every project.


## Root Cause


No quick fixes. Always diagnose to the root cause and devise proper solutions. Never apply patches or workarounds unless the user explicitly asks.


---


## Security & Secrets


- Never hardcode secrets or commit them to git
- Use separate API tokens/credentials for dev, staging, and prod environments
- Validate all input server-side — never trust client data
- Add rate limiting on auth and write operations


## Architecture & Code Quality


- Design architecture before building — don't let it emerge from spaghetti
- Break up large view controllers/components early
- Wrap external API calls in a clean service layer (easier to cache, swap, or extend later)
- Version database schema changes through proper migrations
- Use real feature flags, not commented-out code


## Observability


- Add crash reporting from day one
- Implement persistent logging (not just console output)
- Include a `/health` endpoint for every service


## Environments & Deployment


- Maintain a real staging environment that mirrors production
- Set CORS to specific origins, never `*`
- Set up CI/CD early — deploys come from the pipeline, not a laptop
- Document how to run, build, and deploy the project


## Testing & Resilience


- Test unhappy paths: network failures, unexpected API responses, malformed data
- Test backup restores at least once — don't wait for an emergency
- Don't assume the happy path is sufficient


## Time Handling


- Store all timestamps in UTC
- Convert to local time only on display


## Discipline


- Fix hacky code now or create a tracked ticket with a deadline — "later" never comes
- Don't skip fundamentals just because the code compiles and runs

# FitAI — iOS Fitness Tracking App

## Project Overview
An iOS fitness tracking app built with SwiftUI that covers:
- Workout logging and history
- Macro and micronutrient tracking
- HealthKit integration with Apple Health
- AI-powered generative coaching via the Anthropic API

## Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data**: SwiftData (NOT CoreData)
- **Health Integration**: HealthKit
- **Charts**: Swift Charts (iOS 16+)
- **AI Coaching**: Anthropic API (claude-sonnet-4-20250514)
- **Minimum iOS**: iOS 17.0

## Project Structure
```
FitAI/
├── App/
│   └── FitAIApp.swift
├── Models/
│   ├── Workout.swift
│   ├── Exercise.swift
│   ├── NutritionLog.swift
│   ├── Meal.swift
│   └── UserProfile.swift
├── Views/
│   ├── Dashboard/
│   ├── Workouts/
│   ├── Nutrition/
│   ├── Progress/
│   └── AICoach/
├── Services/
│   ├── HealthKitService.swift
│   ├── AnthropicService.swift
│   └── NutritionService.swift
└── Resources/
    └── Info.plist
```

## Coding Rules

### General
- Always use `@MainActor` for view models
- Use `async/await` for all asynchronous operations — no completion handlers
- Use `@Observable` macro (iOS 17+) for view models, NOT `ObservableObject`
- Prefer value types (structs) over reference types (classes) where possible
- All SwiftData models must use `@Model` macro

### SwiftData
- Use SwiftData for all local persistence
- Define all models in the Models/ directory
- Use `@Query` in views to fetch data reactively
- Never use CoreData

### SwiftUI
- Keep views small and composable — extract subviews aggressively
- Use `#Preview` macros for all views
- Follow Apple Human Interface Guidelines
- Support both light and dark mode — test both

### HealthKit
- Always request permissions before accessing any HealthKit data
- HealthKit permission strings must be declared in Info.plist:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
- Handle cases where HealthKit is unavailable (e.g., iPad without Health app)
- Never assume HealthKit permissions are granted — always check

### Anthropic API (AI Coach)
- Model: `claude-sonnet-4-20250514`
- API key must be stored in a `.env` file or Xcode environment variable — NEVER hardcoded
- Always stream responses for a better UX on the AI Coach screen
- System prompt for AI coach:
  > "You are FitAI Coach, a knowledgeable and supportive fitness and nutrition expert. You give personalized, actionable advice based on the user's workout history, nutrition data, and goals. Keep responses concise (under 200 words unless asked for more), practical, and encouraging."
- Pass relevant user context (recent workouts, nutrition summary, goals) in every API call

### Error Handling
- All HealthKit and API calls must have proper error handling
- Show user-friendly error messages — never expose raw error strings
- Use Swift's `Result` type or `throws` — no force unwrapping (`!`)

## Key Features to Build (in order)

1. **Onboarding** — Name, age, weight, fitness goal (lose fat / build muscle / maintain)
2. **Dashboard** — Daily summary: calories, protein, workouts completed, streak
3. **Workout Logging** — Log exercises, sets, reps, weight; view history
4. **Nutrition Tracking** — Log meals, search foods, track macros (protein/carbs/fat) and key micros (iron, vitamin D, calcium)
5. **Progress Charts** — Weight over time, strength PRs, calorie trends using Swift Charts
6. **AI Coach** — Conversational interface; user describes a problem, AI gives personalised advice with access to their data context

## Commands
```bash
# Build
xcodebuild -scheme FitAI -destination 'platform=iOS Simulator,name=iPhone 16'

# Test
xcodebuild test -scheme FitAI -destination 'platform=iOS Simulator,name=iPhone 16'

# Lint (if SwiftLint installed)
swiftlint lint
```

## Important Notes
- HealthKit does NOT work on the simulator for most data types — test on a real device
- The Anthropic API requires a network connection — handle offline states gracefully
- App Store submission requires a privacy manifest (PrivacyInfo.xcprivacy) for HealthKit usage
- Never log sensitive user health data to the console