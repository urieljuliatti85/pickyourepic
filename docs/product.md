# Product Documentation

Pick Up Your Epic! is a social platform for music curation based on **Epics** — carefully selected moments from songs.

---

## Core Concepts

### Epic

An **Epic** represents a specific time interval within a track.

**Properties:**
- **owner** — The user who created the Epic
- **track** — The Spotify track being referenced
- **start_time** — Start position in milliseconds (>= 0)
- **end_time** — End position in milliseconds (> start_time, <= track duration)
- **title** — User-defined title for the Epic
- **description** — Optional user notes
- **visibility** — public or private

**Rules:**
- An Epic belongs to exactly one user and one track
- A user can create only one Epic per track
- An Epic does not contain audio; it is purely metadata and a reference to a Spotify track

**Example:**
```
Track: "Nocturnal Will" by Dödsrit (5:00 long)
Epic: "The breakdown" (01:00 - 02:30)
Owner: @uriel
```

---

### Pick

A **Pick** represents a user choosing an Epic created by another user.

**Properties:**
- **user** — The user making the Pick
- **epic** — The Epic being Picked

**Rules:**
- A user can Pick the same Epic at most once
- A Pick does not duplicate the Epic; it merely records the user's choice
- When a user Picks an Epic, the original Epic's owner and metadata remain unchanged

---

### Collection

A **Collection** organizes Epics into curated groups.

**Properties:**
- **owner** — The user who created the Collection
- **title** — Collection title
- **description** — Optional description
- **visibility** — public or private

**Rules:**
- A Collection belongs to exactly one user
- A Collection can contain the user's own Epics or Epics they have Picked
- Epics within a Collection can be ordered
- Private Collections do not appear in public discovery

---

## User Flows

### Create an Epic

1. User authenticates with Spotify
2. User searches for a track
3. User previews the track and selects a time interval
4. User provides a title and optional description
5. User sets visibility (public/private)
6. Epic is saved

### Discover Epics

1. Authenticated user navigates to Discover
2. User sees trending Epics (public)
3. User can Preview, Play, or Pick an Epic
4. User can add Picked Epic to a Collection

### Manage Collections

1. User creates a new Collection
2. User adds Epics to the Collection (own or Picked)
3. User can order Epics within the Collection
4. User can set Collection visibility
5. User can play a Collection (plays each Epic in sequence, respecting start/end times)

### View User Profile

1. User navigates to another user's profile
2. If public: User sees the profile's public Epics and Collections
3. If private: User sees only basic profile info
4. User can Play or Pick Epics from the profile

---

## Privacy

### Visibility Levels

**Public**
- Visible in Discover
- Visible on user's public profile
- Appears in trending rankings
- Can be Picked by any user

**Private**
- Hidden from Discover
- Hidden from public profiles
- Cannot be Picked by other users
- Only visible to the owner

---

## MVP Scope

The MVP includes:

- Spotify authentication
- Track search
- Epic creation with time selection
- Epic playback (where Spotify permits)
- Collections (create, add Epics, organize)
- Picks (select other users' Epics)
- Public profiles (view public Epics and Collections)
- Discover (trending public Epics)

### Out of MVP Scope

- Chat and private messaging
- Comments on Epics
- Followers/following
- Advanced notifications
- AI recommendations
- Marketplace or monetization
- Complex gamification

---

## Architecture

### Domain Models

```
User
  ├── has_one SpotifyAccount
  ├── has_many Epics
  ├── has_many Picks
  └── has_many Collections

SpotifyAccount
  └── belongs_to User

Track
  └── has_many Epics

Epic
  ├── belongs_to User
  ├── belongs_to Track
  └── has_many Picks

Pick
  ├── belongs_to User
  └── belongs_to Epic

Collection
  ├── belongs_to User
  └── has_many CollectionEpics

CollectionEpic
  ├── belongs_to Collection
  └── belongs_to Epic
```

### Integration Points

**Spotify**
- OAuth for user authentication
- Track search via Spotify API
- Track metadata (duration, artwork, artist)
- Playback via Web Playback SDK (for premium users)

---

## Development Rules

Detailed development rules, conventions, and constraints are documented in [CLAUDE.md](../CLAUDE.md).

Implementation roadmap and phase breakdown are documented in [ROADMAP.md](../ROADMAP.md).
