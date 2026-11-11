# AstroVitals

AstroVitals is a Flutter astronaut health-monitoring app. Accounts and astronaut
profiles use Supabase Auth and the `public.users` table.

## Connect Supabase

1. Create a Supabase project.
2. In `lib/supabase_config.dart`, set `projectUrl` and `publishableKey` using the
   project URL and publishable (or legacy anon) key from the Supabase dashboard.
   These client values are not a substitute for database security. Never put a
   Supabase service-role/secret key in this app.
3. In the Supabase SQL Editor, run `supabase/schema.sql`. It creates the profile,
   health-record and daily-activity tables if they do not already exist, and
   enables per-user Row Level Security policies. If your dashboard already has
   health tables, compare their columns with the script before applying it.
4. Run `flutter pub get`, then `flutter run -d chrome` or run the app on a
   connected device.

If email confirmation is enabled, a new astronaut confirms their email before
signing in. The profile is created from the signup metadata on their first
successful sign-in. Account credentials and profile data are not stored in an
app-managed in-memory account repository. Supabase Auth persists its session
token on the device so the user remains signed in; profile records live in
Supabase. Health measurements and activity are also saved in Supabase and are
associated with the signed-in Supabase user. Manual and simulated records use
different source values. Simulated smartwatch records use a fixed demo sample,
not a connected wearable.

Health status ranges are configurable in
`lib/data/health_reference_thresholds.dart`. The included prototype values are
not validated for astronaut-specific medical use and must not be used as a
diagnosis.
