# 🏊‍♂️ repSwim – V1 Build Specification (Copilot-Ready)

## 🧠 Goal

Build a **Flutter (iOS + Android)** mobile app called **repSwim** that allows swimmers to:

* Track swim sessions (pool-based)
* Record lap times and intervals
* Track personal bests (PBs)
* View basic analytics
* Track dryland workouts

The app must be:

* Offline-first
* Clean architecture
* Extensible for future AI/video features

---

# 🏗️ 1. Tech Stack

### Frontend

* Flutter (latest stable)
* Dart
* Material 3

### State Management

* Riverpod (preferred) OR Bloc (acceptable)

### Local Storage

* Drift (preferred) OR Hive

### Optional (if needed)

* Freezed (for models)
* go_router (navigation)

---

# 🧱 2. Architecture

Use **feature-first clean architecture**:

```
lib/
 ├── core/
 │   ├── theme/
 │   ├── utils/
 │   ├── constants/
 │
 ├── features/
 │   ├── swim/
 │   │   ├── data/
 │   │   ├── domain/
 │   │   ├── presentation/
 │   │
 │   ├── stopwatch/
 │   ├── pb/
 │   ├── analytics/
 │   ├── dryland/
 │
 ├── app.dart
 ├── main.dart
```

---

# 📊 3. Data Models

## 3.1 SwimSession

```dart
class SwimSession {
  String id;
  DateTime date;
  int totalDistance; // meters
  Duration totalTime;
  String stroke; // freestyle, butterfly, etc.
  List<Lap> laps;
}
```

---

## 3.2 Lap

```dart
class Lap {
  int distance; // meters
  Duration time;
  int lapNumber;
}
```

---

## 3.3 PersonalBest

```dart
class PersonalBest {
  String id;
  String stroke;
  int distance;
  Duration bestTime;
  DateTime achievedAt;
}
```

---

## 3.4 DrylandWorkout

```dart
class DrylandWorkout {
  String id;
  DateTime date;
  List<Exercise> exercises;
}
```

---

## 3.5 Exercise

```dart
class Exercise {
  String name;
  int sets;
  int reps;
  double? weight;
}
```

---

# ⚙️ 4. Core Features (MVP)

---

## 4.1 Swim Tracking

### Requirements:

* Create new swim session
* Add laps manually
* Auto-calculate:

  * Total distance
  * Total time
  * Pace

---

## 4.2 Stopwatch Feature

### Requirements:

* Start / Pause / Stop
* Record lap splits
* Save session from stopwatch

---

## 4.3 Personal Best (PB) Tracking

### Logic:

* When session saved:

  * Check if lap time is best for:

    * stroke + distance
* Update PB table automatically

---

## 4.4 Analytics Dashboard

### Show:

* Weekly distance
* Average pace
* Total sessions
* PB highlights

---

## 4.5 Dryland Tracking

### Features:

* Create workout
* Add exercises
* Save history

---

# 📱 5. UI / Screens

---

## 5.1 Home Screen

### Show:

* Today summary
* Last session
* Quick actions:

  * Start swim
  * Start stopwatch
  * Add workout

---

## 5.2 Swim Session Screen

* Add laps
* Select stroke
* Save session

---

## 5.3 Stopwatch Screen

* Big timer display
* Lap button
* Stop + save

---

## 5.4 PB Screen

* List PBs grouped by stroke
* Highlight best times

---

## 5.5 Analytics Screen

* Charts:

  * Weekly distance
  * Pace trend

---

## 5.6 Dryland Screen

* Workout list
* Add/edit workout

---

# 🔁 6. Navigation

Use `go_router`:

Routes:

```
/home
/swim
/stopwatch
/pb
/analytics
/dryland
```

---

# 🧮 7. Business Logic

---

## 7.1 Pace Calculation

```
pace = totalTime / totalDistance
```

---

## 7.2 PB Detection

Pseudo:

```
for each lap:
  if lap.time < existing PB for (stroke + distance):
    update PB
```

---

## 7.3 Weekly Stats

```
group sessions by week
sum distance
average pace
```

---

# 🗄️ 8. Storage Layer

### Tables:

* swim_sessions
* laps
* personal_bests
* dryland_workouts
* exercises

---

# 🧪 9. Testing

* Unit tests:

  * PB logic
  * pace calculation
* Widget tests:

  * stopwatch
  * session screen

---

# 🎯 10. Copilot Instructions (IMPORTANT)

Use this when prompting Copilot:

---

### Prompt Block:

```
Generate a Flutter app called "repSwim" using Riverpod and Drift.

Requirements:
- Feature-based clean architecture
- Swim session tracking with laps
- Stopwatch with lap recording
- Personal best tracking (auto-calculated)
- Analytics dashboard (basic charts)
- Dryland workout tracking

Constraints:
- Offline-first (local DB only)
- Material 3 UI
- Use go_router for navigation
- Keep code modular and extensible

Start by:
1. Creating project structure
2. Defining models and database schema
3. Implementing swim session feature
4. Implementing stopwatch feature
5. Implementing PB logic
6. Building UI screens

Write clean, production-quality code with comments.
```

---

# 🚀 11. Build Order (Critical)

Tell Copilot to follow this order:

1. Models + DB
2. Swim session feature
3. Stopwatch
4. PB logic
5. UI screens
6. Analytics
7. Dryland

---

# ⚠️ 12. Constraints / Non-Goals (V1)

DO NOT IMPLEMENT:

* AI stroke analysis
* Video processing
* Cloud sync
* Social features

---

# 💡 13. Opinionated Advice (Important)

Don’t over-engineer V1.

Biggest mistake you could make:
👉 Trying to build AI + video too early

Winning move:
👉 Nail **tracking + PB + usability**

If this feels like:

* “simple but solid”
  → you’re doing it right.

---

# ✅ 14. Expected Output

Copilot should generate:

* Full Flutter project
* Working navigation
* Local DB
* CRUD for sessions
* Stopwatch UI
* PB logic working

---

If you want next step, I can generate:

* ✅ Full **Drift schema + DAO layer**
* ✅ **Riverpod providers**
* ✅ **Flutter UI widgets (ready-to-run code)**
* ✅ Or a **backend + sync architecture (Spring Boot / GraphQL)**
