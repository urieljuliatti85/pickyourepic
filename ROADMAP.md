# Pick Up Your Epic! — Roadmap

## Status Legend

- [ ] Not started
- [~] In progress
- [x] Completed
- [!] Blocked

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

### Verification

- [x] User can authenticate with Spotify
- [x] Existing user can log in
- [x] New user is created
- [x] Tokens are not exposed
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

- [ ] Valid Epic can be created
- [ ] Invalid timestamps are rejected
- [ ] Epic belongs to correct user
- [ ] Epic belongs to correct Track
- [ ] Tests pass

---

# Phase 5 — Pick

## Data & Model

- [x] Create Pick model
- [x] Add unique constraint

**Note:** Unique constraint (user_id, epic_id) prevents duplicate picks. Privacy enforcement: cannot pick private epics. Ownership protection: cannot pick own epics. Cascade delete on User and Epic deletion. 22 tests covering all validations and edge cases.

## UI & Controllers (Future)

- [x] Pick Epic (UI/Controller)
- [ ] Unpick Epic (if required by approved scope)
- [x] Display Pick count
- [ ] Display users who Picked where appropriate

**Note:** Nested route POST /epics/:epic_id/picks. PicksController with create action. Form validation via model (private epic, own epic, duplicate). View conditionals protect button visibility. Flash messages for success/error. 12 controller tests + 3 system tests covering all flows and edge cases.

### Verification

- [x] Tests pass (15 testes: 12 controller + 3 system)

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

**Note:** GET /profiles/:username route with param: :username. ProfilesController with show action. Privacy enforcement: private profiles show notice + hide content (except to owner). View shows public epics grid + picked epics grid. 12 controller tests + 3 system tests covering all flows and edge cases.
- [x] Public profile is accessible
- [x] Private content is protected
- [x] Tests pass (15 testes: 12 controller + 3 system)

### Verification

- [ ] Public profile is accessible
- [ ] Private content is protected
- [ ] Tests pass

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

**Note:** 226 tests across 25 test files (110 model, 84 controller, 16 system, 14 integration, 2 helper). Security audit: all write controllers require authentication, all owner-only actions have authorization, all params use strong params or model validation. Bug fix: EpicsController#show changed from owner-only to visibility-based access (public epics visible to all, private only to owner). Database indexes verified on all foreign keys, unique constraints, and case-insensitive username.

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