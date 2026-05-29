# App Store Connect — App Review Information

Paste the blocks below into the matching fields in App Store Connect →
"App Review Information" before submitting the build for review.

---

## 1. Sign-in account (mandatory for force-login apps)

In App Store Connect, tick **"Sign-in required"** and fill in:

- **User name** (email): `apple-review@atlasfit.com`
- **Password**: `<generate a strong 16+ char password and paste here>`

> Create this account in Firebase Console → Authentication → Users → "Add user"
> **before** submitting the build. Use the **same project** the production
> build points to (see `ios/Runner/GoogleService-Info.plist` for the
> `PROJECT_ID`). After creating the auth user, sign in once on a real device
> to complete onboarding so the reviewer doesn't land on the onboarding flow.

### Why an account is required

> AtlasFit is a personalized fitness and nutrition tracker. All core
> screens — workout history, nutrition logs, AI Coach, progress charts,
> Apple Health sync, community feed — are tied to the signed-in user's
> private data. A sign-in is required to demonstrate the app's value;
> no part of the personalized experience works in an anonymous mode.

---

## 2. Notes (reviewer walkthrough)

Paste into the **"Notes"** field:

> Hi Apple Review Team,
>
> Demo credentials are provided above. The account has sample workouts,
> nutrition logs, and a few community posts pre-seeded so every tab
> renders meaningful content.
>
> Recommended walkthrough:
>   1. Sign in with the provided email/password on the Welcome screen.
>   2. Dashboard — daily summary of calories, protein, workouts, streaks.
>   3. Workouts tab — open any logged workout to see exercise/set detail.
>   4. Nutrition tab — tap a meal section to log food via search,
>      barcode scanner, or one of the built-in restaurant builders
>      (e.g. Chipotle, Sweetgreen). The "Other Restaurant" entry uses
>      Spoonacular's menu-item API.
>   5. Community tab — feed of public posts. Reactions, comments,
>      challenges are all live.
>   6. AI Coach tab — conversational fitness coach powered by the
>      Anthropic Claude API. The system prompt and message stream are
>      visible if you tap the icon to test.
>   7. Settings → "About" — version number, privacy/terms links.
>
> Permissions the app will request:
>   - Camera: barcode scanning + challenge proof photos
>   - Photo Library: profile picture + share images
>   - Apple Health: read steps/calories/workouts; write workouts/nutrition
>   - Notifications: workout reminders + streak nudges
>
> No real-money in-app purchases. Coins/gems shown in the theme store
> are earned through app usage (workouts, streaks, PRs); there is no path
> to purchase them, so no IAP entitlement is requested.
>
> The AI Coach uses the official Anthropic Claude API. The user-facing
> system prompt instructs the model to act as a knowledgeable fitness
> and nutrition expert and to keep responses concise. No medical
> diagnosis or prescription advice is offered.

---

## 3. Contact information

Whichever team member is on point for review responses:

- **First name / Last name**
- **Email** (responds within 24h during business days)
- **Phone**

---

## Pre-submission self-check (this side)

Before clicking "Submit for Review":

- [ ] Created `apple-review@atlasfit.com` in Firebase Auth (production project).
- [ ] Signed in once on a real iPhone to clear onboarding for that account.
- [ ] Added one or two workouts + nutrition logs to the demo account so
      tabs aren't empty when the reviewer opens them.
- [ ] Joined one community post + one challenge from the demo account
      so reactions/comments aren't empty.
- [ ] Confirmed `ios/Runner/Info.plist` orientation is **portrait only**
      on iPhone (already locked in this commit).
- [ ] Confirmed the production `firestore.rules` matches
      `firebase_rules_production.txt` (deploy via
      `firebase deploy --only firestore:rules`).
- [ ] Confirmed dev-mode seed buttons (`if (kDebugMode) ...`) are
      compiled out of the release IPA — verify by archiving in Xcode
      with the Release scheme and checking Settings → no Developer
      section appears.
- [ ] Removed any leftover seeded community posts/users from production
      Firestore (or accept that reviewers will see them).
- [ ] Bumped `IPHONEOS_DEPLOYMENT_TARGET` in `Runner.xcodeproj` from
      `13.0` to `15.5` to match the Podfile.

## After acceptance

- Disable email/password sign-up in Firebase Console for the
  reviewer account **OR** rotate the password to invalidate the
  credentials in App Store Connect notes for the next submission.
- Keep the account in Firebase — Apple may re-test on future updates.
