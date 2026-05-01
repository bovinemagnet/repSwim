# 🏊‍♂️ Product Requirements Document (PRD)

## Product: **repSwim**

**Platform:** Flutter (iOS + Android)
**Category:** Swimming Training & Performance Intelligence

---

## 1. 🎯 Vision

**repSwim is the “Strava + Coach + Technique Lab” for swimmers.**

A single app that:

* Tracks **pool + dryland training**
* Measures **performance (PBs, splits, stroke metrics)**
* Improves **technique via AI + video analysis**
* Provides **adaptive coaching + structured workouts**

👉 Key gap in market: existing apps are fragmented (tracking vs coaching vs technique vs recovery) ([GOWOD][1])

---

## 2. 🧠 Problem Statement

Swimmers today:

* Use **multiple apps** (tracking, coaching, mobility) ([GOWOD][1])
* Lack **real-time technique feedback**
* Struggle to track **PBs + intervals + drills**
* Have poor **integration between swim + gym/dryland**

Coaching is either:

* Expensive (human coach)
* Generic (static plans)

---

## 3. 👤 Target Users

### Primary

* Competitive swimmers (teen → masters)
* Triathletes
* Swim squad athletes

### Secondary

* Fitness swimmers
* Beginners learning technique

---

## 4. 🧩 Core Value Proposition

> “Train smarter, swim faster, and fix your stroke — all in one place.”

---

## 5. 🧱 Feature Breakdown (V1 → V3 roadmap)

---

# 🥇 5.1 Core MVP Features (V1)

## 5.1.1 🏊 Swim Session Tracking

**Must-have baseline**

### Features:

* Pool swim tracking:

  * Distance
  * Time
  * Pace
  * Stroke type
* Auto lap detection (watch integration)
* Manual logging fallback

📊 Why:

* Tracking pace + distance is foundational across apps ([GOWOD][1])

---

## 5.1.2 ⏱️ Lap Stopwatch & Interval Timer

### Features:

* Lap timer (manual + auto)
* Interval training builder:

  * Sets, reps, rest
* Voice/audio cues

👉 Critical because structured intervals drive improvement ([MySwimPro][2])

---

## 5.1.3 🏅 PB (Personal Best) Engine

### Features:

* Track PBs per:

  * Distance (25, 50, 100, 200, etc.)
  * Stroke
* Auto-detect PBs
* Historical trend charts

### Advanced:

* “Near PB” alerts
* PB streaks

---

## 5.1.4 📊 Training Analytics Dashboard

### Metrics:

* Distance per week
* Pace trends
* Stroke efficiency (future)
* Consistency score

📊 Data tracking and trend analysis are core motivators in apps like Strava ([GOWOD][1])

---

## 5.1.5 🏋️ Dryland Training Tracking

### Features:

* Gym workouts:

  * Strength
  * Core
  * Mobility
* Custom routines

👉 Critical: swimming performance is strongly influenced by mobility + strength ([GOWOD][1])

---

# 🧠 5.2 AI & Coaching Features (V2)

---

## 5.2.1 🤖 AI Workout Generator

### Input:

* Skill level
* Goal (PB, endurance, technique)
* Available time

### Output:

* Structured workouts (intervals, drills)

📌 Inspired by:

* MySwimPro AI workouts ([myswimpro.com][3])

---

## 5.2.2 📹 AI Stroke Analysis (CORE DIFFERENTIATOR)

### Flow:

1. User uploads video
2. AI analyzes:

   * Body position
   * Stroke timing
   * Kick efficiency
3. Outputs:

   * Score
   * Issues
   * Fix suggestions

📌 Similar concept exists:

* Video feedback + stroke scoring systems ([App Store][4])

---

## 5.2.3 🎥 Video Coaching Tools

![Image](https://images.openai.com/static-rsc-4/zQB3ruIY3CeDk5gYGqpB2HYoRX8QME7_nBKcOkOX32InjKK2Z9ssgZqy27Qedkpbl93EKRoki1Z0cdp16BDoere1yUmZgCCf0Ypn6BD2pO7nG2adfzYIX3-kyzw7LFICqj9dm6WIbxSHANIhjusKq1Ewz_xOjy6VhrIn0gTrGH3LE8q027hedIgQdbllVorg?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/ebyGMwL-jGDu4fZYNKfBakTHcYIAiHlcBSO6fBCdwGJ4Bbf1mjokc0UK-X8XCO80L0xUwhFF1cnzhoA8xo9jlJZLYfo3iRetPFRVRAP-rOKCmfXZ1y1_NyaLEfoXhskmGz6tZcgv1W8amueHglOt7Ee2Q-Hc3i4wq5g71nBo9ZuInJYh5tbyYa20l0-3pmKa?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/wY_B-VQL2Run1jq8FKjiWl-Vf2PSVF2C1uF0Nu--LvkhCf-0Dp4a_PfvwcZ5ScBfodLTYsj3GhCH_HaujTCiBFAeXK1XgO3WGutCgMITYc5t1Dvh17l8D_tn2MBPvs3mZ70sKmL4W_lJdcDkifq8IdHgIa5Xc_TYhRJp1qPhpRuj_sefL-To-f3Etsr9SGlV?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/PX39_fl5aOqYDDTmBS4rEHSAM-jWe9Ew0TMV3wdWx2sElbPZahGNsSDApbdPoi1X7wwkU0ZGppX9YS7INAhNWy1QIJPk5meXxNlM2MSbR-91inMrZOk5Pfy7ufirQspxekwSiM9nSV72N_23AVce-hj8I4BCLXzF6KsA2jfW_MdG02zDi7XWS2chppcVlTCw?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/LqQ0b0_7EWsegViPEVCMF6Hq0W3OQ0FnAdFUQObDRnBo2I0lfRpTwDyXkYWuaUrXouVTo2i1SBNm49-fVglzCq4OnOLPcizGl5nblRj8Y0zjY1klYrov2BorP68q4vSRmROzWPaAvkyfV0k9WEegYxkCShB1Qi48WGqheWoPml_zG11rQy6XCy0DnXemeYTq?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/dto8bY8L2T-NNFQa4bjz8m6nqHOlAUQuxCpMxvptmdeHtugxMvZ2RM_RVDycjQNQ_vyxMoywHzRaz4B2somof0_IyD9AZXi2IrDpLZYxsIVGh5qammAzNrqmFQOqU-Vg0zF1ZzDdRBZrvm-3WC-_jyi7QcLN7uIsDUOOPcuZeAo7kpjoUK3jRpTz0A243BC_?purpose=fullsize)

### Features:

* Slow motion
* Side-by-side comparison
* Drawing overlays
* Multi-angle support

📌 Proven approach:

* Video + annotation improves technique rapidly ([Onform][5])

---

## 5.2.4 🧬 Technique Library

### Content:

* Freestyle, backstroke, breaststroke, butterfly
* Drills + corrections

### Example strokes:

* Front crawl (fastest stroke)
* Butterfly (high power, high fatigue) ([Wikipedia][6])

---

# 📈 5.3 Advanced Features (V3)

---

## 5.3.1 🧠 Adaptive Training Engine

### Behavior:

* Adjust workouts based on:

  * Performance
  * Missed sessions
  * Fatigue

📌 Inspired by adaptive coaching apps ([App Store][4])

---

## 5.3.2 🥽 Wearable Integration

### Devices:

* Apple Watch
* Garmin
* Smart goggles

### Metrics:

* Stroke rate
* Stroke length
* Pace

📊 Example:

* FORM app tracks stroke rate + pacing over time ([FORM Australia][7])

---

## 5.3.3 🌊 Open Water Mode

* GPS tracking
* Route maps
* Stroke detection

---

## 5.3.4 🧑‍🤝‍🧑 Social & Gamification

* Clubs / squads
* Leaderboards
* Challenges

---

## 5.3.5 🧘 Recovery & Mobility Module

* Stretch routines
* Injury prevention

📌 Recovery improves performance and reduces injury risk ([GOWOD][1])

---

# 🎨 6. UX / UI Concepts

---

## Key Screens

### 1. Dashboard

* Today’s workout
* Weekly stats
* PB highlights

---

### 2. Swim Session Screen

* Big lap timer
* Interval display
* Real-time feedback (future)

---

### 3. Video Analysis Screen

* Upload video
* Annotated playback
* AI insights panel

---

### 4. Training Plan Screen

* Calendar view
* Adaptive adjustments

---

# 🧱 7. Technical Architecture (Flutter-first)

---

## Frontend (Flutter)

* Clean architecture (feature-based)
* Offline-first capability

## Backend

* Firebase / Supabase (fast start)
* Later:

  * ML service (Python / TensorFlow)
  * Video processing pipeline

---

## AI Components

* Pose estimation (e.g. MediaPipe)
* Stroke classification
* Feedback engine

---

# 📊 8. Key Metrics (Product Success)

* Weekly active users
* Training session frequency
* PB improvements
* Video uploads (engagement proxy)
* Retention (critical)

---

# 💰 9. Monetization Strategy

### Freemium:

* Free:

  * Basic tracking
  * PB tracking
* Paid:

  * AI stroke analysis
  * Training plans
  * Advanced analytics

---

# 🧠 10. Competitive Positioning

| App         | Strength           | Weakness           |
| ----------- | ------------------ | ------------------ |
| MySwimPro   | Structured plans   | Weak technique AI  |
| Strava      | Tracking + social  | No coaching        |
| FORM        | Real-time data     | Hardware dependent |
| Swim Smooth | Technique coaching | Less tracking      |

👉 repSwim = **all-in-one system**

---

# 🚀 11. Unique Differentiators

### 1. AI stroke analysis (mobile-first)

### 2. Integrated dryland + swim tracking

### 3. PB-first design (competition mindset)

### 4. Video + data fusion (rare combo)

---

# ⚠️ 12. Risks

* AI accuracy (hard problem)
* Video capture quality
* Over-complex UX

👉 Recommendation:
Start **tracking + PB + workouts first**, then layer AI.

---

# 🧭 13. Suggested MVP Scope (Realistic)

If I were building this:

### Build first:

* Swim tracking
* Interval timer
* PB tracking
* Basic analytics

### Then:

* Workout generator
* Video upload + manual analysis

### Then:

* AI stroke analysis

---

# 💡 Final Opinion (Important)

You’re trying to build a **category winner**, not just an app.

Most swimming apps fail because they:

* Do **one thing well**
* But don’t connect everything

👉 The winning move:
**Make repSwim the swimmer’s “daily operating system.”**

---

If you want, I can next:

* Design the **data model (Postgres / JPA-friendly)**
* Outline **Flutter architecture (feature modules, state mgmt)**
* Or spec the **AI stroke analysis pipeline in detail**

[1]: https://www.gowod.app/blog/best-swimming-apps-for-performance-tracking-and-recovery?utm_source=chatgpt.com "Best Swimming Apps To Track, Train & Improve Performance"
[2]: https://blog.myswimpro.com/2024/08/16/best-swim-workout-app/?utm_source=chatgpt.com "Best Swim Workout App"
[3]: https://www.myswimpro.com/?utm_source=chatgpt.com "MySwimPro app"
[4]: https://apps.apple.com/us/app/swim-success-swim-workout-app/id6751714673?utm_source=chatgpt.com "Swim Success: Swim Workout App - App Store"
[5]: https://onform.com/sports/swimming/?utm_source=chatgpt.com "Swimming Video Analysis App and Coaching Solution"
[6]: https://en.wikipedia.org/wiki/Swimming_stroke?utm_source=chatgpt.com "Swimming stroke"
[7]: https://au.formswim.com/pages/swimming-app?utm_source=chatgpt.com "FORM Swim App for Apple and Android"
