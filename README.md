# 🪖 iMilitaryCalisthenics

> Native military-style calisthenics training plans for iOS — personalized by weight, height, age and goal, built entirely with SwiftUI.

[Report Bug](https://github.com/VidiPT89/iMilitaryCalisthenics/issues) · [Request Feature](https://github.com/VidiPT89/iMilitaryCalisthenics/issues)

## ✨ Features

- ✅ Personalized onboarding — weight, height, age, sex, fitness level, goal, days per week and available equipment
- ✅ Periodized 4–8 week training plans (linear progression with automatic deload weeks)
- ✅ Four goal tracks: fat loss, strength & mass, military endurance and general mobility
- ✅ Adaptive intensity based on BMI signal, age band and fitness level — never a diagnosis, just smarter volume
- ✅ Full military calisthenics catalog: push-ups, pull-ups, dips, squats, burpees, sprints, planks and more
- ✅ Warm-up → strength → circuit/HIIT → core → cool-down structure for every session
- ✅ Animated progress ring, spring transitions and satisfying per-exercise completion states
- ✅ Looping stick-figure demo animation and coaching cue for every exercise, drawn natively — no video files, fully offline
- ✅ Correct exercise posture in the demos — floor exercises animate on a horizontal axis, standing exercises on a vertical one
- ✅ Weight log with trend sparkline — logging a new weigh-in recalibrates the plan's intensity to match, no re-onboarding needed
- ✅ Share a day's or week's workout as plain text via the native share sheet
- ✅ Optional local workout reminders on your training days, at a time you pick
- ✅ In-app PT-PT / EN language switch, independent of the device locale
- ✅ Fully offline, local persistence with SwiftData
- ✅ Native app icon and dark, brand-matched launch screen — no white flash on cold start

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| Language | Swift 5 |
| UI | SwiftUI |
| Architecture | MVVM |
| Persistence | SwiftData |
| Project generation | XcodeGen |
| Minimum target | iOS 17 |

## 🚀 Quick Start

**Prerequisites:** Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

1. Clone the repo
   ```bash
   git clone https://github.com/VidiPT89/iMilitaryCalisthenics.git
   cd iMilitaryCalisthenics
   ```
2. Generate the Xcode project
   ```bash
   xcodegen generate
   ```
3. Open and run
   ```bash
   open MilitaryCalisthenics.xcodeproj
   ```

## 📖 Usage

On first launch, fill in your profile (weight, height, age, level, goal,
training days and equipment) and tap **Generate plan**. The app builds a
multi-week plan split into daily workouts — browse weeks and days from the
top selectors, tap an exercise to mark it done, and track completion with
the animated progress ring. Switch language and edit your profile anytime
from the Settings tab.

## 🧪 Testing

The `MilitaryCalisthenicsTests` target covers the `PlanEngine` core:
deterministic generation across the full input matrix (edge ages and
weights, every goal/level/equipment combination), correct week/day counts,
higher volume for advanced levels, BMI-signal-driven intensity changes,
age-band adjustment, goal-specific exercise counts, and plan recalibration
after logging a new weigh-in. Run with:

```bash
xcodebuild -project MilitaryCalisthenics.xcodeproj \
  -scheme MilitaryCalisthenics \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**
🌐 Website: [ividi.dev](https://ividi.dev)
🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89)

## 🤝 Contributing

Contributions, issues and feature requests are welcome — feel free to check the [issues page](https://github.com/VidiPT89/iMilitaryCalisthenics/issues).

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a><br>If you found this useful, consider leaving a ⭐</p>
