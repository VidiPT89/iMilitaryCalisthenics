# Plan engine specification

Platform-agnostic description of the calisthenics plan generator. Both the
iOS (`PlanEngine`) and Android (`planengine`) implementations must follow
this document; when the algorithm changes, update this file first, then
port the change to both platforms in the same task.

## Input

- `weightKg: Double` (30–250)
- `heightCm: Double` (120–230)
- `age: Int` (14–75)
- `sex`: male / female / unspecified — optional, only affects volume calibration
- `level`: beginner / intermediate / advanced
- `goal`: fatLoss / strengthMass / militaryEndurance / mobility
- `daysPerWeek: Int` (3–6)
- `equipment`: `Set<Equipment>` of bodyweightOnly / pullUpBar / parallettes,
  at least one — a real independent set on both platforms as of
  2026-08-30 (iOS previously stored a single value; see "Equipment model"
  below).
- `sessionMinutes: Int` (15–60, step 5, default 30) — how much time the
  user has for a single workout; scales the *number* of exercises per
  block instead of a fixed count, see "Session duration budget" below

## Output

A `TrainingPlan` containing `level.progressionWeeks` `WeeklyPlan`s
(beginner 4, intermediate 6, advanced 8 — both platforms as of
2026-08-30; Android previously always generated a fixed 6 regardless of
level). Each week has `daysPerWeek` `DailyWorkout`s, each with warm-up,
strength, core, and cool-down blocks always present, plus circuit only
when `includeCircuit(goal, label)` allows it for that day (see "Day
split & movement pattern filtering" below):

1. Warm-up
2. Strength
3. Circuit / HIIT (conditional)
4. Core
5. Cool-down

Each block has a list of exercises with either `reps` or `seconds`, plus
`sets`.

## Equipment model (unified 2026-08-30)

Both platforms now store `equipment` as a `Set<Equipment>` — the user can
independently toggle "Pull-up bar" and "Parallettes" on top of the always
-available bodyweight baseline, exactly like Android already did.
iOS previously stored a single `Equipment` value behind a single-choice
picker where selecting "Parallettes" implicitly also granted pull-up-bar
exercises (since the UI framed the three options as cumulative tiers).
That implicit assumption no longer holds now that the two are
independent toggles, so `ExerciseCatalog.availableStrength` on iOS was
changed to check `equipment.contains(.pullUpBar)` on its own — matching
Android's `Equipment.PULL_UP_BAR in profile.equipment` — instead of
granting pull-bar exercises whenever parallettes was picked.

## Calibration

`multiplier = levelMultiplier * ageMultiplier * bmiMultiplier * sexMultiplier * weekProgression`

- `levelMultiplier`: beginner 0.7, intermediate 1.0, advanced 1.3
- `ageMultiplier`: <25 → 1.1, 25–39 → 1.0, 40–54 → 0.85, ≥55 → 0.7
- `bmiMultiplier` (BMI = weightKg / (heightM²), used only as a volume
  signal — never a diagnosis or a gate): <18.5 → 0.9, 18.5–24.9 → 1.0,
  25–29.9 → 0.9, ≥30 → 0.75
- `sexMultiplier` (average upper-body strength/endurance calibration,
  never a gate on goal or exercise selection): male 1.0, female 0.9,
  unspecified 1.0
- `weekProgression` (linear periodization across 6 weeks): `1.0 + weekIndex * 0.08`

`multiplier` scales base rep counts, hold durations and set counts (rounded,
sets clamped to 2–5, reps/seconds floored at 1).

## Day split & movement pattern filtering (unified 2026-08-30)

Both platforms now split days by the **same fixed, goal-independent
pattern** based on `daysPerWeek` (iOS `PlanEngine.splitLabels`, Android
`PlanEngine.splitLabels` — identical scheme, just localized separately by
each platform's own translation table):

- 3 days → Full Body I / II / III
- 4 days → Upper Body / Lower Body / Full Body / Conditioning
- 5 days → Upper Body / Lower Body / Push / Pull / Conditioning
- 6 days → Upper Body / Lower Body / Push / Pull / Conditioning / Mobility

Before 2026-08-30, Android instead cycled goal-specific title lists
(Push Strength, Selection Prep, Mobility Flow, ...) that only actually
constrained exercise selection for the `strengthMass` goal — every other
goal's titles were decorative. Every strength-block exercise is tagged
with a `push`, `pull`, or `legs` movement pattern, and the engine filters
the pool down to the patterns the day's label allows — **for every goal**,
not just strengthMass, as of this unification:

- `Upper Body` → push + pull
- `Lower Body` → legs only
- `Push` → push only
- `Pull` → pull only
- anything else (Full Body/Full Body I-III/Conditioning/Mobility) → all
  three patterns

If filtering a pool down to the allowed patterns would leave it empty
(should not normally happen given the catalog below), the engine falls
back to the unfiltered pool rather than producing an empty block.

**Bodyweight-only pull option**: before the 2026-08-29 fix, a user with
only bodyweight equipment had *zero* pull-pattern exercises available at
all (pull-ups required a bar) — a `pull`-focused day for that user silently
fell back to whatever else was in the pool. Both platforms now include an
Inverted Rows / Table Rows fallback (`exercise.invertedRows` on iOS) in the
bodyweight-only pool.

**Weekly rotation**: exercise selection now rotates by `dayIndex + weekIndex`
(previously `dayIndex` alone), so the same day of the week doesn't show an
identical exercise selection every week of a 4-8 week plan — it varies
across weeks in addition to varying across days. Rotation stays fully
deterministic (same profile → same plan), it's not randomized.

## Blocks

**Warm-up** (fixed, not scaled): jumping jacks 60s, arm circles 30s,
bodyweight squats x15, hip openers 30s.

**Strength pool** (base reps before scaling, `sets` scaled from base 3),
tagged by movement pattern and filtered/rotated per "Movement pattern
filtering" above:
- push: push-ups x12, wide push-ups x10, diamond push-ups x8 (iOS,
  intermediate+), pike push-ups x8; plus equipment-dependent: parallel bar
  dips x8 if `parallettes` else bench dips x10.
- pull: pull-ups x6 (intermediate+) and chin-ups x6 if `pullUpBar`, else
  inverted/table rows x10.
- legs: bodyweight squats x18, lunges x12, glute bridges x15 (same pool on
  both platforms as of this fix — Android's leg pool previously only had
  squats+lunges).

**Circuit** (rounds scaled from base 3), goal-specific pools, filtered by
level and age and rotated by day+week (fixed 2026-08-29 — previously a
static list per goal with no rotation and no level/age filtering at all).
Included only when `includeCircuit(goal, label)` allows it — identical
rule on both platforms as of 2026-08-30: `fatLoss`/`militaryEndurance`
every day, `strengthMass` only on the `Conditioning` day, `mobility`
never (no circuit block at all for that goal, on either platform):
- militaryEndurance: burpees x10 (skip over-40), mountain climbers 40s, sprint intervals 30s, high knees 30s, shuttle runs 30s, bear crawl 30s
- fatLoss: burpees x8 (skip over-40), jump squats x12 (skip over-40), mountain climbers 40s, high knees 30s, bear crawl 30s
- strengthMass: mountain climbers 30s, explosive push-ups x6 (intermediate+), jump squats x14 (skip over-40, iOS)/plus diamond push-ups (intermediate+, iOS only) — deliberately excludes pike/diamond push-ups from reappearing here on Android since they already live in the strength pool's push list and reusing them let the same exercise appear twice in one day

If level-filtering a circuit pool would leave it empty (e.g. a beginner on
strengthMass's conditioning day, where 3 of 4 exercises are intermediate+),
the engine falls back to the age-filtered pool rather than producing an
empty block — mountain climbers exists in that pool specifically so
beginners always have at least one valid option before the fallback is
ever needed.

**Age safety**: `skipOverForty` circuit exercises (high-impact plyometric
moves — burpees, jump squats) are excluded for `age > 40` on both
platforms as of 2026-08-29 — previously only iOS had this exclusion,
Android had none.

**Level gating extended to the strength pool on Android** (2026-08-29):
Pike Push-ups now requires intermediate+ on Android too, matching iOS —
previously Android had no level gating anywhere, so a first-day beginner
could be handed Pike Push-ups.

**Core** (sets fixed at 3, all scaled by multiplier), pool expanded from
3 to 7 exercises on 2026-08-29 (previously so small that Plank alone
covered ~67% of days on iOS, and 100% of days on Android since Android
additionally had no rotation at all): plank 45s, side plank 30s, mountain
climbers (core) 35s, Russian twists x20, leg raises x12, bicycle crunches
x20, superman hold 20s. Rotated by day+week the same way as strength.

**Mobility goal swaps Core for mobility drills on both platforms**
(2026-08-29 — previously Android always trained abs even on the Mobility
goal, unlike iOS): hip openers 30s, cat-cow 10x, shoulder circles 30s,
thoracic rotations 30s, ankle circles 20s, deep squat hold 30s (pool
expanded from 3 to 6 on iOS for the same reason as Core above).

**Cool-down** (fixed, not scaled): deep breathing 60s, hamstring stretch 30s, shoulder stretch 30s.

## Session duration budget

`sessionMinutes` does not change intensity — it changes how many exercises
each variable block gets, so a workout fits roughly in the chosen time. This
is a comfort estimate, not a precision stopwatch: real duration depends on
the user's pace.

**Per-exercise time estimate** (used only for this budgeting step, not
shown as a guarantee): `exerciseSeconds = sets * (workSeconds + restSeconds)`,
where `workSeconds` is `seconds` for a timed exercise, or
`reps * secondsPerRep` (`secondsPerRep = 3`) for a rep-based one.

**Fixed blocks**: warm-up (~3 min) and cool-down (~2 min) always keep their
current exercise count — they don't scale with `sessionMinutes`.

**Variable blocks** (strength, circuit, core) split the remaining time
(`sessionMinutes * 60 - warmupSeconds - cooldownSeconds`, floored at 0) by
weight:
- With a circuit block: strength 50%, core 20%, circuit 30%.
- Without one (e.g. `mobility` goal, or `strengthMass` on non-conditioning
  days): strength 65%, core 35%.

Each variable block picks the largest exercise count (using the same
rotation/`pick` selection already used for exercise choice) whose estimated
total time does not exceed its sub-budget, clamped to a minimum of 1
exercise and a maximum of the available pool size for that block.

## Weight tracking & recalibration

The user's weight is not a one-time onboarding value — it is logged over
time as a history of `(date, weightKg)` entries, kept alongside the
profile (not overwriting it in place). Whenever a new entry is logged:

1. The active profile's `weightKg` is updated to the new value.
2. The plan is regenerated from scratch through the same `Calibration`
   function above, using the *current* `weightKg` together with the
   profile's unchanged `heightCm`, `age`, `level` and `goal` — so the
   `bmiMultiplier` (and therefore volume/intensity) tracks the user's
   real bodyweight over the course of their training instead of staying
   frozen at whatever value was entered during onboarding.
3. Per-exercise completion state resets (a new plan invalidates old
   week/day/exercise keys), and the week/day selection resets to the
   start of the new plan.
4. Both apps show a lightweight trend view (hand-drawn line/sparkline,
   not a charting library) of the weight history, and a simple "log
   weight" form (weight + date, defaulting to today) reachable from
   Settings.

This lets the same goal (fat loss, strength/mass, military endurance,
mobility) stay selected while the plan's difficulty adapts automatically
as the user's weight changes — no need to redo onboarding.

## Plan completion

A plan is "complete" once every exercise/workout in its **final week** is
marked done (per-exercise on iOS via `completedExerciseIDs`, per-workout
on Android via `DailyWorkout.completed`). Neither platform previously
detected this — the UI simply stayed on the last week with no signal.

Both apps now show a completion prompt at that point, offering the two
paths the engine already supports without sending the user back through
onboarding:

1. **Repeat this level** — re-run `PlanEngine.generate` against the same
   profile (iOS `regeneratePlan()`, Android `regeneratePlan()`), resetting
   progress to week 1.
2. **Level up** — move `level` to the next `FitnessLevel`
   (beginner → intermediate → advanced, `nil`/`null` past advanced) and
   regenerate (iOS `levelUp()`, Android `levelUp()`), also resetting
   progress to week 1. Hidden/disabled once already at `advanced`.

This is intentionally *not* an automatic reassessment (no auto-adjustment
of reps/weight based on perceived difficulty) — it is a manual choice
presented to the user at the natural end-of-cycle moment, reusing existing
engine entry points.

**Resolved 2026-08-30** (was a known cross-platform divergence): both
platforms now vary total weeks by level via `progressionWeeks` (beginner
4, intermediate 6, advanced 8) — Android's `PlanEngine` previously always
generated a fixed 6 weeks regardless of level.

## Guided workout session (timer)

Both apps offer a "Start workout" entry point from the day's workout that
opens a sequential, full-screen session walking through every block in
order (warm-up → strength → circuit → core → cool-down), exercise by
exercise, set by set:

- **Timed exercise** (`seconds` set): a visual countdown of `seconds`;
  auto-advances to rest when it hits zero.
- **Rep-based exercise** (`reps` set): no countdown — there's no way to
  detect reps completed — shows the target rep count and a "Done" button
  the user taps to advance to rest.
- **Rest**: a countdown of `restSeconds` between sets/exercises, with a
  "Skip rest" button.
- Controls: pause/resume, skip exercise, exit (in-view confirmation state,
  not a native OS alert/dialog, to avoid blocking the countdown loop).
- Finishing the last block marks the day complete using each platform's
  existing completion mechanism (iOS: `completedExerciseIDs` per exercise;
  Android: `DailyWorkout.completed` per day) — no new completion model.

## UX notes shared by both apps

- In-app language toggle (PT-PT / EN), default PT, persisted locally,
  independent of system locale.
- Dark palette from ividi.dev everywhere (see brand colors in each
  platform's theme file) — no system/dynamic colors.
- Credits screen: "Developed by David Arsénio Martins", link to
  https://ividi.dev/, link to https://github.com/VidiPT89/.
