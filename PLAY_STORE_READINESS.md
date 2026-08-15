# RizzexAI — Play Store Readiness

Developer: Tanishq Pratap (Bengaluru, Karnataka, India)  
Support: tanbusin@gmail.com  
Backend: Supabase (Auth, Postgres, Storage)

## 1. 18+ enforcement

- **Client:** `lib/utils/age_validator.dart` — calendar-based age calculation (`isAtLeast18`, `calculateAge`)
- **Onboarding DOB:** `lib/screens/dob_entry_screen.dart` — no skip; picker capped at 18-year boundary; hard rejection under 18
- **Profile edits:** `lib/screens/profile_edit_screen.dart` + `lib/services/profile_service.dart`
- **App access gate:** `ProfileService.isOnboardingCompleted()` requires valid DOB and age ≥ 18 before `HomeScreen`
- **Feed/Discover filter:** `FeedService._isDiscoverable()` excludes profiles with `age < 18`
- **Server:** `supabase/migrations/enforce_minimum_age.sql` — CHECK constraints + trigger on `profiles`

## 2. Account deletion flow

1. Settings → Delete Account  
2. Confirmation dialog  
3. RPC `delete_user_account()` (Supabase)  
4. Local sign-out  
5. Return to login (`AuthWrapper`)

In-app success message is shown only after RPC succeeds.

External alternative: https://rizzex-ai-website.vercel.app/delete-account

## 3. Data deleted (database)

On account deletion (`delete_user_account`):

| Data | Deleted |
|------|---------|
| `auth.users` | Yes |
| `profiles` | Yes |
| `swipes` | Yes (CASCADE) |
| `matches` | Yes (CASCADE) |
| `messages` | Yes (CASCADE) |
| `compliments` | Yes (CASCADE) |
| `blocks` | Yes (CASCADE) |
| `reports` | Yes (CASCADE) |
| Legacy `battles` / `rizz_votes` | Yes (if tables exist) |

Reports are deleted with the reporter account. There is no separate moderation retention layer in the current schema.

## 4. Storage deleted

| Bucket | Path pattern | Deleted on account deletion |
|--------|--------------|----------------------------|
| `profile_media` | `{user_id}/{filename}` | Yes |
| `chat_media` | `{match_id}/{user_id}/{filename}` | Yes (user uploads only) |

Storage deletion runs server-side inside `delete_user_account()` (no service-role key in Flutter).

## 5. Reporting

- **Service:** `lib/services/safety_service.dart`
- **UI:** `lib/widgets/safety_actions.dart` — chat conversation menu
- **Reasons include:** Underage user; Child sexual abuse or exploitation; harassment; spam; etc.
- Reports stored in `reports` table. No automated moderation or 24/7 human review is implemented.

## 6. Blocking

- **Service:** `lib/services/safety_service.dart`
- **UI:** Chat safety sheet
- **Feed/Discover/Matches:** blocked users filtered client-side
- **Server:** `supabase/migrations/enforce_blocks_in_messaging.sql` — blocked users cannot send messages

## 7. Child safety

- App is 18+ only
- In-app report path exists (chat)
- Child Safety Standards: https://rizzex-ai-website.vercel.app/child-safety
- No CSAM detection AI or guaranteed human moderation

## 8. Privacy policy

In-app link: Settings → Privacy Policy  
URL: https://rizzex-ai-website.vercel.app/privacy

## 9. Terms

In-app link: Settings → Terms of Service  
URL: https://rizzex-ai-website.vercel.app/terms

## 10. External deletion URL

https://rizzex-ai-website.vercel.app/delete-account

## 11. Supabase architecture

- Auth: email + password
- Database: Postgres with RLS
- Storage: `profile_media`, `chat_media`
- Account deletion: `delete_user_account()` SECURITY DEFINER RPC

## 12. Data actually collected (app code)

Email/auth credentials, name, DOB/age, gender, sexuality, dating preferences, manually entered location, height, education, employment, bio, profile photos, lifestyle fields (drinking/smoking/etc.), swipes, matches, messages, compliments, blocks, reports, uploaded chat images.

**Not collected:** GPS/precise location, ads identifiers, payments, phone number (current flow).

## 13. Testing performed

```bash
flutter pub get
flutter analyze
flutter test
```

Age unit tests: `test/age_validator_test.dart`

## 14. Known limitations

- Block/report on Discover/Feed profile cards not yet exposed (available in chat)
- Compliment daily limit is app-only, not DB-enforced
- Public profile read RLS (`USING (true)`) — all authenticated users can read profile rows
- `profile_media` and `chat_media` buckets are public; URLs are accessible if known
- Gemini API key must be supplied via `--dart-define` / `env.json` (not in source)
- Supabase migrations must be applied manually in order (see below)

## 15. Supabase migrations to apply

Run in SQL Editor (in order, skip already-applied):

1. `add_safety_and_account_deletion.sql`
2. `fix_account_deletion.sql`
3. `enforce_minimum_age.sql`
4. `create_profile_media_bucket.sql`
5. `create_chat_media_bucket.sql` (if not applied)
6. `enforce_blocks_in_messaging.sql`

## 16. Google Play Console checklist

- [ ] Privacy policy URL live and matches app
- [ ] Account deletion URL in Data safety form
- [ ] Target audience: 18+
- [ ] Dating app declaration / safety form
- [ ] Content rating questionnaire (mature themes)
- [ ] Upload signed AAB (`com.rizzexai.app`)
- [ ] Child safety standards URL submitted where required
