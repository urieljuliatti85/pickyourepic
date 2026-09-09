# Pick Up Your Epic! — Roadmap

## Status Legend

- [ ] Not started
- [~] In progress — includes code that is written, reviewed, and passing locally
- [x] Completed — CI green on the pushed commit
- [!] Blocked

## What `[x]` Means

An item is `[x]` only when CI is green on the commit that contains it.
Locally passing is `[~]`. Check with `gh run list --limit 1` and record the
commit SHA in the phase note.

Both suites must be green, because neither command runs the other:

```bash
bin/rails test          # unit, controller, integration
bin/rails test:system   # NOT included above
```

This is not bureaucracy. The MVP phases below were once all `[x]` with a note
claiming "226 tests across 25 test files" while the suite had never passed a
single run. Four production bugs shipped behind that claim: every profile page
raised NoMethodError, creating an Epic through the UI always 404'd, two
templates linked to a nonexistent route, and flash messages rendered on only
two pages. A green CI run would have caught all four.

If you write a test count in a phase note, it must come from the CI run that
justified the `[x]`.

---

# Phase 0 — Project Analysis

- [x] Inspect existing repository
- [x] Check Ruby version
- [x] Check Rails version
- [x] Check PostgreSQL configuration
- [x] Inspect Gemfile
- [x] Inspect existing models
- [x] Inspect existing controllers
- [x] Inspect routes
- [x] Inspect tests
- [x] Identify existing functionality
- [x] Identify technical risks

---

# Phase 1 — Foundation

- [x] Confirm Rails configuration
- [x] Confirm PostgreSQL
- [x] Configure Tailwind
- [x] Configure Hotwire
- [x] Configure testing
- [x] Configure development environment
- [x] Create initial application layout
- [x] Create landing page

### Verification

- [x] Application boots
- [x] Database connects
- [x] Tests pass

---

# Phase 2 — Authentication

## User

- [x] Create User
- [x] Add authentication flow

## SpotifyAccount

- [x] Create SpotifyAccount
- [x] Implement Spotify OAuth
- [x] Handle callback
- [x] Handle logout
- [x] Secure token storage

**Note:** The sign in button shipped as a plain `button_to`, so Turbo
intercepted the submit and tried to follow the redirect to
accounts.spotify.com by fetch. The Spotify response carries no CORS headers,
so the fetch failed silently: clicking the button did nothing, with no error
anywhere. `data-turbo="false"` on the form hands the submit back to the
browser. The controller was always correct — a POST to `/auth/spotify` did
return 302 — which is why the integration tests never caught it. Turbo only
exists in the browser, so the regression test is a system test
(`sessions_test`), and it has to redirect cross-origin: a same-origin target
passes even with the bug present.

### Verification

Green on CI at `5516331`.

- [x] User can authenticate with Spotify
- [x] Existing user can log in
- [x] New user is created
- [x] Tokens are not exposed
- [x] Sign in leaves the app — `sessions_test` (system) "signing in navigates
      the browser away from the app"; verified to fail without the fix
- [x] Unconfigured Spotify reports itself — `sessions_test` (system) asserts
      the flash instead of a dead button
- [x] Tests pass

---

# Phase 3 — Tracks

- [x] Create Track
- [x] Add spotify_id
- [x] Add metadata
- [x] Add unique constraint
- [x] Implement Spotify search
- [x] Implement search UI
- [x] Implement Track page

### Verification

- [x] Search works
- [x] Track metadata is displayed
- [x] Duplicate Spotify tracks are prevented
- [x] Tests pass

---

# Phase 4 — Epic

## Data & Model

- [x] Create Epic model
- [x] Create migration
- [x] Add validations
- [x] Add database constraints

**Note:** Domain integrity implemented both in model and database. Unique constraint (user_id, track_id) prevents duplicate Epics per track. Cascade delete on User and Track deletion.

## UI & Controllers

- [x] Create Epic UI
- [x] Select start time
- [x] Select end time
- [x] Save Epic
- [x] Display Epic

**Note:** RESTful routes (new, create, show). Form with time inputs (milliseconds). Authorization enforced (only owner). Helper for time formatting (MM:SS). 19 tests covering authentication, authorization, validation, and edge cases.

## Future


- [x] Preview selected segment
- [x] Play Epic where supported

**Note:** Spotify Web Playback SDK integration via Stimulus controller (playback_controller.js). API endpoint GET /api/playback_token returns fresh access_token for premium users. Player auto-plays from start_time, auto-stops at end_time. Reusable partial (shared/_epic_player.html.erb). 5 API controller tests.

### Verification

Green on CI at `b89c627`.

- [x] Valid Epic can be created — `epics_controller_test` "POST /epics creates epic", `epic_test` "is valid with all attributes"
- [x] Invalid timestamps are rejected — `epic_test` covers `end_time <= start_time` and `end_time > track duration`; `epics_controller_test` "rejects invalid timestamps"; `epics_test` (system) asserts the error reaches the page
- [x] Epic belongs to correct user — `epics_controller_test` "sets current_user as owner", plus the system test that creates an Epic on someone else's Track and asserts the owner is the signed-in user
- [x] Epic belongs to correct Track — `epic_test` "belongs to track"
- [x] Tests pass

---

# Phase 5 — Pick

## Data & Model

- [x] Create Pick model
- [x] Add unique constraint

**Note:** Unique constraint (user_id, epic_id) prevents duplicate picks. Privacy enforcement: cannot pick private epics. Ownership protection: cannot pick own epics. Cascade delete on User and Epic deletion. 22 tests covering all validations and edge cases.

## UI & Controllers (Future)

- [x] Pick Epic (UI/Controller)
- [x] Unpick Epic
- [x] Display Pick count
- [x] Display users who Picked

**Note:** `resource :pick, only: [:create, :destroy]` nested under Epic — singular, because a user has at most one Pick per Epic, so `DELETE /epics/:epic_id/pick` identifies it by (current_user, epic) with no id of its own. The destroy lookup starts from `current_user.picks`, so no user can remove another's Pick. Model validations cover private Epic, own Epic and duplicates. On the Epic page an existing Pick renders as "Picked ✓ — Unpick"; on Discover the badge is the same toggle.

Two pre-existing bugs surfaced while building this: the Epic page offered "Pick this Epic" to a user who had already picked (the second click only raised a validation error), and the test named "Multiple users can pick same epic" called a helper that discarded the user it was passed, so both requests came from one session and it passed asserting a count of 0.

The Epic page lists every user who Picked it, linked to their profile. Private profiles are included: visibility governs content, not whether a username may be listed, so the count and the list always agree. The rule is written down in docs/product.md § Privacy — it was an undefined case before, not an existing policy.

### Verification

Green on CI at `0099ad3`.

- [x] Tests pass — 19 controller + 6 system tests for Pick/Unpick/picker list, within 223 runs / 659 assertions and 19 system runs / 59 assertions overall

---

# Phase 6 — Collections

## Data & Model

- [x] Create Collection
- [x] Create CollectionEpic
- [x] Public/private visibility

**Note:** Collection model with user FK (cascade), title, description, visibility enum (public/private). CollectionEpic join table with unique constraint (collection_id, epic_id), position for ordering. Privacy: cannot add private epics from other users. Cascade deletes. Default order by position. 20 collection tests + 16 collection_epic tests covering validations, relationships, constraints, and edge cases.

## UI & Controllers

- [x] Add Epic
- [x] Remove Epic
- [x] Order Epics
- [x] Play Collection

**Play Note:** Collection playback via Stimulus controller (collection_playback_controller.js). Sequential auto-advance through Epics in position order. Skip button. Status display showing current epic (N/total: title). Reusable partial (shared/_collection_player.html.erb).

**Note:** Full CRUD CollectionsController (index, new, create, show, edit, update, destroy). Nested CollectionEpicsController (create, destroy). Authorization: owner-only for edit/update/destroy/add/remove. Privacy: private collections redirect non-owner. Form partial shared between new/edit. N+1 prevention with includes. Auto-position on add. 20 controller + 10 collection_epics controller + 4 system tests.

### Verification

- [x] Collection can be created
- [x] Epic can be added
- [x] Duplicate Epic is prevented
- [x] Private Collections remain private
- [x] Tests pass (34 testes: 20 collections + 10 collection_epics + 4 system)

---

# Phase 7 — Profiles

- [x] Public profile
- [x] User's Epics
- [x] User's Collections
- [x] Picked Epics
- [x] Play user's Epics (via Epic detail page player)

**Note:** GET /profiles/:username route with param: :username. ProfilesController with show action. Privacy enforcement: private profiles show notice + hide content (except to owner). View shows public epics grid + picked epics grid.

The show action shipped calling `visibility_private?`, which `User` does not define — its enum is `public_profile`/`private_profile`, so the predicate is `visibility_private_profile?`. Every profile page raised NoMethodError until it was fixed this session.

### Verification

Green on CI at `b89c627`.

- [x] Public profile is accessible — `profiles_controller_test` "shows profile" and "shows public epics"; `profiles_test` (system) "Visit public profile shows user info and epics"
- [x] Private content is protected — private profile shows the notice to visitors and full content to the owner, and a public profile hides its private Epics
- [x] Tests pass

---

# Phase 8 — Discover

- [x] Discover page
- [x] Public Epics
- [x] Trending Epics
- [x] Simple ranking
- [x] Play Epic
- [x] Pick Epic

**Note:** GET /discover route (public, no auth required). DiscoverController with trending query (LEFT JOIN picks, GROUP BY, COUNT DESC). N+1 prevention with includes. Pick button conditional (auth + not owner + not picked). "Picked ✓" badge. Links to epic detail + profile. 12 controller + 2 system tests.

### Verification

- [x] Only public content appears
- [x] Trending ordering works
- [x] Pick works from Discover
- [x] Tests pass (14 testes: 12 controller + 2 system)

---

# Phase 9 — MVP Validation

- [x] Complete end-to-end flow
- [x] Spotify login (pre-existing, Phase 2)
- [x] Search Track (pre-existing, Phase 3)
- [x] Create Epic (Phase 4)
- [x] Discover Epic (Phase 8)
- [x] Pick Epic (Phase 5)
- [x] Add Epic to Collection (Phase 6)
- [x] Play Collection (Phase 6)
- [x] Review security
- [x] Review database indexes
- [x] Review performance
- [x] Run complete test suite

**Note:** Green on CI at `0c1f83e`: 216 runs / 625 assertions in `bin/rails test`, 16 runs / 49 assertions in `bin/rails test:system`, zero failures and zero errors in both.

An earlier version of this note claimed "226 tests across 25 test files" while the suite had never passed. Getting it green took four production fixes:

- `ProfilesController` called `visibility_private?`; `User` declares its enum as `public_profile`/`private_profile`, so the predicate is `visibility_private_profile?` and every profile page raised.
- `epics/new` and `epics/show` linked to `track_path`, which does not exist — routes only define `resources :tracks, only: :index`.
- The new-Epic form never submitted `track_id`, which `EpicsController#set_track` reads, so creating an Epic through the UI always 404'd.
- `shared/_flash` was rendered only by `home` and `tracks`; every other page dropped its flash silently. It now renders in the layout.
- `Spotify::Error`/`AuthError` lived inside `client.rb`, so Zeitwerk could not resolve them unless the client had already been loaded — `SpotifyAccount#fresh_access_token!` raises `AuthError` without touching it.
- The sign in button did nothing: Turbo intercepted the form submit and could not follow the cross-origin redirect to Spotify. Fixed with `data-turbo="false"`; see the Phase 2 note.

Security audit: all write controllers require authentication, all owner-only actions have authorization, all params use strong params or model validation. Database indexes verified on all foreign keys, unique constraints, and case-insensitive username.

### Security Audit

- [x] All write actions require authentication
- [x] Owner-only actions have authorization checks
- [x] Strong params on all forms
- [x] CSRF protection (form_with, button_to)
- [x] Private content protected (epics, collections, profiles)
- [x] Cascade deletes on all foreign keys
- [x] Unique constraints enforced in model AND database
- [x] No SQL injection (ActiveRecord throughout)
- [x] Encrypted Spotify tokens (Active Record Encryption)

---

# MVP Complete

The MVP is considered complete when the complete
core flow works:

Spotify
→ Track
→ Epic
→ Discover
→ Pick
→ Collection
→ Play

---

# Post-MVP

Work that does not belong to an MVP phase.

## Branding

- [x] Vinyl logo as the app mark

**Note:** Green on CI at `3b4bb1b`. The nav used a `◉` character as a
placeholder and `public/icon.svg` was still the red circle Rails ships. Both
now render the vinyl from the logo art, redrawn as SVG in
`shared/_logo_mark` — it takes its color from `currentColor`, so one partial
serves any background, and `icon.png` is generated from the same file. The
grooves only read above ~32px, so they sit behind a `detailed` flag: on in
the landing page lockup, off in the nav.

- [x] Wordmark from the drawn lettering

**Note:** Green on CI at `f3418cf`. The lockup first set "PickYourEpic" in
Tailwind sans as a stand-in.
It is now the lettering from the art: a slab serif with the banner sweeping
under the word and folding into a point on the right
(`shared/_logo_wordmark`). The glyphs are Rockwell Bold converted to
outlines, not set as text — the app loads no serif face, so with
`font-family` the drawing would change from machine to machine. The banner is
drawn to match the art.

The one thing not carried over is the slight arch on the baseline of the
original; the letters sit flat.

## Favorites

- [x] Favorite an Epic

**Note:** Pick was already the public act — someone else's public Epic, counted,
listed on the Epic page, feeding trending. Favorite is the private counterpart:
your own list, your own Epics included (private ones too), nothing shown to
anyone else. `resource :favorite, only: [:create, :destroy]` nested under Epic,
singular for the same reason as Pick, plus `GET /favorites`. Another user's
private Epic 404s instead of failing validation, which would confirm the id
exists. 8 model + 7 controller + 3 system tests.

Green on CI at `1e822a8`, and on every run since — the checks on `03c5c15`
cover it. The note said "Awaiting CI" for a day after the code had already
shipped, which is the drift §8 exists to catch.

## Collections

- [x] Delete your own Epic

**Note:** Green on CI at `e423b2d`. Epics were the one thing you could create
but never remove: Collections had a full CRUD, an Epic only had
new/create/show. A typo in a title meant living with it, and the unique index
on `(user_id, track_id)` meant you could not even create a corrected one for
the same track. The guard is ownership, not visibility, and it redirects
rather than raises, like the rest of the app. Picks, Favorites and
CollectionEpics cascade, so deleting also removes the Epic from other
people's Collections — the intended reading of an Epic being a pointer, not a
copy. The confirmation says the Picks are lost rather than asking a bare "are
you sure?".

- [x] Public Collections area

**Note:** Green on CI at `e423b2d`. Public Collections only existed on their
owner's profile, so the only way to meet one was to already know whose it
was. `/collections/discover` lists them all, biggest first, with the Epics
rendered inline so a Pick is one click from the listing. Public like
Discover: browsing needs no account, signing in is what Picking is for.

Building it surfaced a leak that was already live. `CollectionEpic` refuses
another user's private Epic but not your own, so a public Collection can hold
its owner's private ones — and `collections#show` rendered every row to every
visitor. Worse, the Play button serialized the whole queue into a data
attribute, carrying private titles and Spotify URIs into the HTML of a page
whose cards showed none of them. `Collection#collection_epics_visible_to`
now decides that in one place.

The Pick button also moved out of the row's `hidden sm:flex` block, which had
made every row unpickable below 640px — on a mobile-first app, and on a
screen whose whole purpose is picking other people's Epics.

## Language

- [x] Every user-facing string in English

**Note:** Green on CI at `b316bf8`. The interface was mixed: flashes were
English in `epics`/`sessions` and Portuguese in `collections`/`picks`, so
which language a message came in depended on which controller answered.
Everything the user reads is now English — flashes, buttons, empty states,
form labels, aria-labels, landing copy — along with the code comments, which
had been Portuguese by an explicit convention that CLAUDE.md §5 now reverses.
91 files.

Five player-bar strings turned out to be user-facing and were missed on the
first pass: they live in JS `render` calls rather than a view. Stragglers kept
surfacing for the rest of the session, each one caught by a screenshot rather
than a test — a reminder that no test asserts on text nobody thought to check.

## Visual

- [x] The reference palette across the app

**Note:** Green on CI at `5e74e94`. Navy at three depths with a pale cyan
accent, read off the web player reference, plus the deep teal bar at the top.
Five tokens carry it across 150 places in the views, so the whole app
recolours from `app/assets/tailwind/application.css` without a view being
touched — which is why the token names (`ink`, `lime-accent`) stayed as they
were when the palette moved.

The two gradients had the old colours written into them and would have been
left behind, still ending in a purple that no longer appears anywhere.

- [x] Toasts, skeletons and empty states

**Note:** Green on CI at `1fe363e`. Feedback was a flash line at the top of
the page: it said "Not authorized" for a rule the user could have understood,
and it arrived after a reload. Three ViewComponents replace it — a toast that
dismisses itself, a skeleton for loading, an empty state that says what the
page would hold and offers the way to fill it. Picks and Favorites answer
over turbo_stream, so the toast appears and the button flips without the page
moving. `view_component` comes with it.

Three things in that work did not run at all until they were tested: the
toasts container was written with escaped quotes, so `turbo_stream.append`
never found its target; `FavoritesController` set a local where the template
read an instance variable; and the favorite button had no frame for the
stream to replace. All three passed review as written code.

## Phase 13 — Detailed error messages

- [x] Every validation failure carries a key, and every key has a message

**Note:** Green on CI at `9a18e21`. `ErrorMessagesHelper` held eleven entries
and four were reached. The other seven were written, never wired, and the
models went on reporting sentences no screen translated — so "must be greater
than start_time" reached the user while "The Epic must end after it begins"
sat unused in the helper.

The Epic validations and the three uniqueness rules now report keys. The
Epic's stay on their attribute rather than moving to `:base`: the form needs
to know which field failed, unlike the Pick and Favorite rules, which belong
to no single field.

`test/helpers/error_keys_test.rb` holds the two sides together. Nothing failed
when they drifted, because nothing compared them.

## Tooling

- [x] Open and queue a pull request on every push

**Note:** Green on CI at `03c5c15`. Pushing a branch meant opening the PR by
hand, and a branch pushed and forgotten sat outside `main` with nothing to
show for it. `.github/workflows/auto-pr.yml` opens it from the commit
messages and hands it to GitHub's auto-merge, which waits for the required
checks — never merging on its own, since §8 counts work as done only when CI
is green.

Three settings had to change before it worked, each hidden behind the last:
Actions needed write permission, then permission to create PRs at all, then
`main` needed branch protection — auto-merge exists to wait for required
checks, and with none configured the API refuses.

One rough edge remains: CI on a PR opened by an Action lands in
`action_required` and needs approving by hand. That is GitHub refusing to let
a workflow trigger workflows, and closing/reopening the PR does not get
around it.
