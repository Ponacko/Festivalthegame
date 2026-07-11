# Festival: The Game — v1 Design

> Canonical vocabulary lives in `/CONTEXT.md`; architectural decisions in `/docs/adr/`.
> This document is the v1 scope agreed in the design session. Anything under
> "Parked" is explicitly out of v1.

## High Concept
A top-down 2D festival score-chaser. You attend a procedurally generated
multi-day music festival biased toward your own music taste, managing personal
Needs and a finite Budget while maximizing a single **Enjoyment Score** by
seeing the right Sets, up close, in good condition.

## Platform & Tech
- **Android / iOS first.** GDScript on Godot 4.6 (mono editor build, but no C#).
- Tap-to-move controls; touch delivered as mouse events via `emulate_mouse_from_touch`.
- Fully offline: no runtime network calls. Music data ships as bundled assets.

## The Core Equation
Enjoyment Score is earned **per game-minute of a Set actually attended**:

```
points_per_minute = artist_affinity        # 1.0 favorite → decays with genre
											#   distance → 0.10 floor
				  × audience_zone_multiplier   # Back 1.0 / Mid 1.15 / Front 1.3
				  × needs_state_multiplier     # 0.25 wrecked → 1.25 thriving
```

- The **Enjoyment Score is monotonic** — nothing ever subtracts from it.
- Every failure costs **time and earning rate**, never points.

## Time
- 1 real second = 1 game minute. A Festival Day (~14 arena hours) ≈ 15 real min;
  a full Run ≈ 1 hour.
- Fast-forward is a **player choice**, never automatic. You may leave any Set
  early; enjoyment accrues only for minutes watched.

## The Festival (procedural, v1 baseline)
- 3 Festival Days, arena roughly 11:00–01:00.
- 4 Stages (one Main, two mid, one small tent); Artist popularity maps to Stage size.
- ~100–120 Artists, one Set each (45–75 min + changeovers).
- Player's Favorite Artists are guaranteed scheduled, with **deliberate Schedule
  Conflicts** injected each Run.

## Personalization (no APIs in v1)
- Player types up to ~10 Favorite Artists and tags each with a **Genre** via
  searchable autocomplete over the bundled **MusicBrainz** taxonomy (~2,000 genres).
- Affinity decays continuously with **genre-graph distance**; the generator biases
  the Lineup toward the player's tastes. See `docs/adr/0001`.

## Needs (six)
Hunger, Thirst, Energy, Bladder, Social, **Mood** (the design's old "Fun").
Combined state multiplies Enjoyment earned.
- **Collapse** (Hunger/Thirst/Energy empty) → wake at the First Aid Tent later,
  need partly restored, Mood floored. Lost time only.
- **Bladder** empty → accident: Mood crash + Social penalty until changed at camp.
- **Social/Mood** can't hard-fail; they bottom out at the multiplier floor.
- Solo play (0 Friends) is viable: Social drains slower, topped up by crowd atmosphere.

## Movement & Map
- Single continuous map, no fast travel. Walking is the universal cost.
- Crowds are a **speed field** (up to ~2× slowdown near popular Sets), not blockers.
- **Audience Zones** (Front/Mid/Back) trade enjoyment vs. crowd cost.
- **Mosh Pits**: opt-in zone at mosh-genre Sets — Mood + bonus, heavy Energy drain,
  Injury risk (halved speed + Mood debuff until First Aid). Time cost only.

## Resources
- Fixed **Budget** per Run, no earning mid-festival. Free water taps are the
  survival floor (Thirst always solvable without money).
- **Vendors** from archetypes; each item = price, restoration, Mood bonus,
  poisoning risk. Location-based price markup. Crowd-scaled **Queues**.
- **Food Poisoning**: delayed-onset timed affliction. Time cost only.
- **Alcohol** is explicit and cartoonish (varieties differ by stats/price);
  **Tipsy** boosts Mood/Social, wobbles movement, drains Bladder, saps next-day
  Energy. **Zero drugs, ever.**

## Friends (0–4, autonomous company)
- Each has a taste profile and own schedule; provide Social/Mood income and a
  shared-experience Enjoyment bonus when nearby.
- No dialogue trees / relationship meters. One verb via the **Group Chat**:
  "meet me at X" (accept/decline by their own schedule). Group shares one camp.

## Camp & Night
- **Campsite** chosen once at Run start: trade-off areas (walk distance vs. sleep
  quality vs. nightlife).
- Night = sleep (Energy recovery = hours × campsite quality, hurt by noise/Tipsy)
  vs. party at camp (Social/Mood, Energy keeps draining). Late-night food near camp.

## Presentation
- Pixel art, ~32px characters; CC0 placeholder packs for v1.
- Bundled genre-tagged royalty-free loop packs over festival-PA filtering + crowd noise.

## Persistence & Ending
- **Ironman**: one continuously-autosaved Run, no manual save/load; quit and resume.
- Morning recap per day; final scoreboard with per-Set breakdown, war stories
  (disasters as time cost), and score as **% of a theoretical max** for the festival.
- Local high-score table. No online leaderboards in v1.

## Success Condition
Maximize the Enjoyment Score before the Festival ends.

## Parked (not v1)
Real-data import (music services, real festivals, setlists) · meta-progression /
equipment · earning money mid-festival · retry-same-seed mode · Hygiene need ·
online leaderboards · hearing music outside Audience Zones · monetization/store
strategy · tutorial/onboarding polish · weather.
