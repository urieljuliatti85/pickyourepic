# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Section numbers are referenced from code comments (`# ... (CLAUDE.md §7)`). When renumbering sections, update those references — `grep -rn "CLAUDE.md §" app lib test`.

---

## 1. Product

Pick Up Your Epic! é uma plataforma social de descoberta e curadoria musical baseada em momentos específicos de músicas.

O usuário conecta sua conta Spotify, encontra uma música, seleciona um trecho e salva esse momento como um Epic. Outros usuários podem ouvir, descobrir e Pickar esses Epics.

Product detail lives in `docs/product.md`. Phase-by-phase scope lives in `ROADMAP.md`.

### Core concepts

**Epic** — an interval (`start_time`..`end_time`, in milliseconds) of a Track, owned by a User. An Epic **never contains audio**; it is a pointer into a Spotify track.

**Pick** — a user choosing someone else's public Epic. A Pick does not duplicate the Epic; it records the choice. One Pick per user per Epic.

**Collection** — a user's ordered grouping of Epics: their own Epics, or public Epics from others (picked or not).

---

## 2. Commands

Development server (Puma + Tailwind watcher via Foreman):

```bash
docker compose up -d      # Postgres 17 on host port 5433
bin/setup                 # bundle, db:prepare, then exec bin/dev
bin/dev                   # web + tailwindcss:watch
```

Tests:

```bash
bin/rails test                                  # unit + controller + integration (NOT system)
bin/rails test test/models/epic_test.rb         # one file
bin/rails test test/models/epic_test.rb:42      # one test by line number
bin/rails test -n /pick/                        # by name pattern
bin/rails test:system                           # Capybara + Selenium, run separately
```

The parallel workers hang against the Docker Postgres on some machines: the
run sits at zero output until it is killed. When that happens, force the suite
serial with `PARALLEL_WORKERS=1 bin/rails test` — the whole suite takes about
ten seconds that way, so this is a cheap default when in doubt. The pre-commit
hook has its own knob for the same problem (`git config hooks.parallelWorkers`,
see below).

Full local CI — the same steps GitHub Actions runs:

```bash
bin/ci                    # see config/ci.rb
```

Individual checks:

```bash
bin/rubocop -a            # rubocop-rails-omakase style
bin/brakeman --no-pager   # static security analysis
bin/bundler-audit         # gem CVEs
bin/importmap audit       # JS dependency CVEs
```

Note: `bin/ci` runs `bin/setup --skip-server`, which touches the development database. `bin/rails test` alone is the fast loop.

### Pre-commit hook

`bin/setup` points `core.hooksPath` at `.githooks/` (versioned, unlike
`.git/hooks/`). The `pre-commit` hook runs RuboCop on the commit's Ruby files
and then `bin/rails test`, and refuses the commit if either fails.

It checks the **staged** content: unstaged work is stashed for the duration and
restored afterwards, so a dirty working tree neither leaks into the check nor
gets lost. System tests stay out of it — they need Chrome and take ~16s against
~6s for the rest; CI enforces them (`config/ci.rb`).

Tests run serially, because the parallel workers hang against the Docker
Postgres on some machines. To use parallelism: `git config hooks.parallelWorkers
auto` (or a number). To skip the hook for one commit: `git commit --no-verify`.

### Environment

Secrets come from `.env` via dotenv (development/test only) — see `.env.example`. `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` are required for any Spotify flow; without them `Spotify::Config.configured?` is false and sign-in short-circuits with a flash instead of raising.

The Spotify dashboard redirect URI must be exactly `http://127.0.0.1:3000/auth/spotify/callback` (Spotify rejects `localhost`).

`SpotifyAccount#access_token` / `#refresh_token` use Active Record encryption, so `config/master.key` (or `RAILS_MASTER_KEY`) must be present or those columns cannot be read.

---

## 3. Architecture

### The Spotify boundary

The domain must not know Spotify's wire format. Three layers, in `lib/spotify/`:

- `Spotify::Config` — credentials and OAuth scopes. Knows no models.
- `Spotify::Client` — raw HTTP (Net::HTTP). Speaks only Hashes and raises `Spotify::Error` / `Spotify::AuthError`. Knows no models.
- `Spotify::Search` — normalizes Spotify search payloads into the attribute hashes `Track.upsert_from_spotify!` accepts.

`SpotifyAuthentication` (in `app/models/`, a plain service object, not an AR model) is the seam: it takes an already-normalized profile + tokens hash and returns a domain `User`, creating `User` + `SpotifyAccount` in one transaction.

Consequence for tests: nothing hits the network. `test/test_helper.rb` stubs `Spotify::Client.exchange_code` / `.me` directly.

### Token lifecycle

Never read `spotify_account.access_token` directly for an API call. Always go through `SpotifyAccount#fresh_access_token!`, which refreshes when `token_expired?` (with a 60s leeway) and persists the new token. Spotify only sometimes returns a new `refresh_token`; the existing one is preserved when absent — do not overwrite it with nil.

### Playback

Playback is Spotify Web Playback SDK only, in the browser, and requires **Spotify Premium** (`SpotifyAccount#premium?`, from the `product` field). `preview_url` is deliberately not used: apps created after 2024-11-27 have no access to it.

`GET /api/playback_token` (`Api::PlaybackController`) hands the browser a fresh access token — authenticated, and 403 for non-Premium. The Stimulus controllers `playback_controller.js` (single Epic) and `collection_playback_controller.js` (sequential Collection playback) start the track at `start_time` and stop at `end_time` on a timer.

### Authentication

Hand-rolled OAuth in `SessionsController`. The `omniauth*` gems are in the Gemfile but are **not used anywhere** — do not assume an OmniAuth strategy exists:

- `POST /auth/spotify` starts the flow. It is POST so a third-party link cannot trigger login.
- CSRF on the callback is covered by the `state` param, compared with `ActiveSupport::SecurityUtils.secure_compare`; `skip_forgery_protection` applies to `:callback` only.
- `sign_in` calls `reset_session` first (session fixation).

`Authentication` (concern in `app/controllers/concerns/`) provides `current_user`, `signed_in?`, and `require_authentication`. It is included in `ApplicationController`, but is **not** applied globally — each controller opts in with `before_action :require_authentication`. `HomeController`, `DiscoverController`, `ProfilesController`, and `EpicsController#show` are intentionally public.

### Authorization

There is no authorization gem. Visibility is enforced per-controller with `before_action` guards that redirect (never raise), plus model-level validations for the rules that must hold regardless of entry point:

- `Pick` — cannot pick a private Epic; cannot pick your own Epic.
- `Favorite` — cannot favorite another user's private Epic (your own, public or private, is allowed). The controller 404s on another user's private Epic rather than raising a validation error, which would confirm the id exists.
- `CollectionEpic` — cannot add another user's private Epic.

Private content must never appear in Discover or on another user's profile.

---

## 4. Domain rules and where they are enforced

Rules that matter exist in **both** the model and the database.

| Rule | Model | Database |
|---|---|---|
| `start_time >= 0` | `Epic` validation | check constraint `epics_start_time_non_negative` |
| `end_time > start_time` | `Epic` validation | check constraint `epics_end_time_greater_than_start` |
| `end_time <= track.duration_ms` | `Epic` validation | — (track-dependent) |
| one Epic per user per track | — | unique index on `(user_id, track_id)` |
| one Pick per user per Epic | `Pick` uniqueness | unique index on `(user_id, epic_id)` |
| one Favorite per user per Epic | `Favorite` uniqueness | unique index on `(user_id, epic_id)` |
| one Epic per Collection | `CollectionEpic` uniqueness | unique index on `(collection_id, epic_id)` |
| username case-insensitively unique | `User` uniqueness | unique index on `lower(username)` |
| `tracks.duration_ms > 0` | `Track` validation | check constraint `tracks_duration_positive` |

All times are **integer milliseconds** (matching Spotify's `duration_ms` and `position_ms`).

Every foreign key is `on_delete: :cascade` except `spotify_accounts.user_id`.

`Track.upsert_from_spotify!` rescues `RecordNotUnique` — the unique index, not a `find_or_create`, resolves the race between two concurrent searches for the same track.

`User#to_param` is `username` and `Track#to_param` is `spotify_id`, so routes use handles and Spotify IDs, not numeric ids. `EpicsController` looks tracks up with `find_by!(spotify_id: params[:track_id])`.

Both `Epic` and `Collection` use `enum :visibility, { public: 0, private: 1 }, prefix: :visibility` → `visibility_public?` / `visibility_private?`. `User` uses a different naming: `{ public_profile: 0, private_profile: 1 }` → `visibility_public_profile?`.

---

## 5. Conventions

**Rails first.** Prefer native Rails over adding a gem. There is no mocking gem, no authorization gem, no pagination gem — `test/test_helper.rb` defines a ~15-line `stub_method` helper rather than pulling in mocha.

**No premature abstraction.** Introduce a service only for a meaningful application operation or an external integration (Spotify auth, search, token refresh). Do not create service objects for their own sake. Controllers stay thin; logic goes in the model or the integration layer.

**MVP discipline.** Do not build what is not in the MVP: no chat, DMs, comments, followers, advanced notifications, AI recommendations, marketplace, monetization, or gamification. Implement only the requested ROADMAP phase; do not advance to the next one on your own.

**Stack reality check.** Solid Queue / Solid Cache / Solid Cable and Active Storage are installed but currently unused — no jobs, no attachments, no `active_storage_*` tables. Avatars are external Spotify URLs (`users.avatar_url`), not attachments.

**Frontend.** Mobile-first Tailwind, server-rendered ERB with Turbo. Reach for Stimulus only where server-rendered HTML genuinely cannot do the job (currently: Web Playback SDK). No SPA. JavaScript is delivered via importmap — there is no bundler and no `node_modules`.

**Language.** Everything in this repository is written in English: identifiers, code comments, user-facing copy (flash messages, buttons, empty states, aria-labels), product docs, commit messages, and this file. Copy lives inline in the views — there is no I18n locale file, so a string is changed where it is written, and adding one is the move if a second language is ever wanted.

Comments explain *why*, not *what* — see `SpotifyAccount#fresh_access_token!` or `Track.upsert_from_spotify!` for the intended density.

---

## 6. Spotify policy constraints

- Do not store or download Spotify audio. Store metadata only.
- Do not circumvent playback restrictions.
- Never expose `SPOTIFY_CLIENT_SECRET` to the client. The token endpoint uses HTTP Basic; the secret never appears in a body or in the frontend.
- Before implementing anything touching playback, verify current Spotify API capabilities and policy — they change (e.g. `preview_url` removal).

---

## 7. Testing

Minitest, run in parallel by processor count. Test types live in `test/models`, `test/controllers`, `test/integration`, and `test/system`.

There are **no fixtures** — `fixtures :all` runs against an empty directory. Build records inline; `create_signed_in_user` in `test/test_helper.rb` is the shortcut for a user with a linked `SpotifyAccount`.

Helpers available in every test: `stub_method`, `with_spotify_configured`, `spotify_profile`, `spotify_tokens`, `stub_spotify_oauth`. Integration tests additionally get `sign_in_as`, which drives the real OAuth controller flow with stubbed HTTP.

Every domain rule needs a test. Every important user flow needs an integration or system test.

---

## 8. Definition of done

A ROADMAP item becomes `[x]` when CI is green on the pushed commit — not
when the code is written, and not when it passes locally. Until then it is
`[~]`. Verify with `gh run list --limit 1`, and record the commit SHA in the
phase note.

This rule exists because it was already broken once: the MVP phases were
marked complete and the notes claimed "226 tests across 25 test files"
while the suite had never passed a single run. Four production bugs shipped
behind that claim — every profile page raised, creating an Epic through the
UI 404'd, two templates linked to a route that does not exist, and flash
messages never rendered outside two pages.

The rest of the checklist:

- implementation complete;
- tests exist and pass — **both** `bin/rails test` and `bin/rails test:system`,
  since the first excludes the second. Both `bin/ci` and GitHub Actions do run
  the system suite (`config/ci.rb` has a "Tests: System" step; the workflow has
  a `system-test` job alongside `test`), so a green CI covers them — but
  `bin/rails test` alone, the fast local loop, does not;
- migrations applied and `db/schema.rb` committed;
- security considerations addressed;
- no unrelated features introduced.

A phase note that states a test count must be the count from the green run
that justified the `[x]`. If you did not read it off CI, do not write it.
