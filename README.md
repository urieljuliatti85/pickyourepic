# Pick Up Your Epic!

Pick Up Your Epic! is a social platform for discovering and collecting the most important moments in music.

Users connect their Spotify account, select a specific moment from a track and save it as an Epic. Other users can discover, listen to and Pick those Epics.

---

## Stack

- **Ruby** — 3.3.0+
- **Ruby on Rails** — 8.1.3+
- **PostgreSQL** — 9.5+
- **Hotwire** — Turbo + Stimulus
- **Tailwind CSS** — Utility-first CSS
- **Testing** — Minitest + Capybara
- **OmniAuth** — Spotify OAuth

---

## Requirements

- Ruby: 3.3.0 or later
- Rails: 8.1.3 or later
- PostgreSQL: 9.5 or later
- Bundler: latest

---

## Setup

### Clone the repository

```bash
git clone https://github.com/urieljuliatti85/pickyourepic.git
cd pickyourepic
```

### Install dependencies

```bash
bundle install
```

### Configure environment

Copy `.env.example` to `.env` (when available) and configure:

```bash
# Spotify OAuth credentials
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_client_secret

# Database
DATABASE_USER=pickyourepic
DATABASE_PASSWORD=pickyourepic
DATABASE_HOST=localhost
DATABASE_PORT=5433
```

### Setup database

```bash
bin/rails db:create
bin/rails db:migrate
```

### Run the application

```bash
bin/dev
```

The app will be available at `http://localhost:3000`.

---

## Testing

Run the full test suite:

```bash
bin/rails test
```

Run a specific test file:

```bash
bin/rails test test/models/epic_test.rb
```

Run with verbose output:

```bash
bin/rails test --verbose
```

---

## Development

The project follows Rails conventions and design principles documented in [CLAUDE.md](./CLAUDE.md).

For product roadmap and feature phases, see [ROADMAP.md](./ROADMAP.md).

For product concepts and core features, see [docs/product.md](./docs/product.md).

---

## License

TBD
