# Pick Up Your Epic!

## 1. Project Overview

Descrição curta do produto.

Pick Up Your Epic! é uma plataforma social de descoberta
e curadoria musical baseada em momentos específicos de músicas.

O usuário conecta sua conta Spotify, encontra uma música,
seleciona um trecho e salva esse momento como um Epic.

Outros usuários podem ouvir, descobrir e Pickar esses Epics.

---

## 2. Core Product Concepts

### Epic

Um Epic representa um intervalo específico de uma Track.

Um Epic possui:

- owner
- track
- start_time
- end_time
- title
- description
- visibility

O Epic NÃO contém áudio.

---

### Pick

Pick representa um usuário escolhendo um Epic criado por outro usuário.

Um usuário não pode fazer Pick do mesmo Epic duas vezes.

O Pick não duplica o Epic.

---

### Collection

Collection organiza Epics.

Uma Collection pertence a um usuário e pode conter
Epics próprios ou Epics que o usuário Pickou.

---

## 3. Product Principles

### Rails First

Preferir funcionalidades nativas do Rails antes de adicionar gems.

### Simplicity

Não criar abstrações prematuras.

### MVP Discipline

Não implementar funcionalidades que não estejam no MVP.

### Domain Integrity

Regras importantes devem existir tanto na aplicação
quanto no banco quando apropriado.

---

## 4. Technology Stack

- Ruby
- Ruby on Rails
- PostgreSQL
- Hotwire
- Turbo
- Stimulus
- Tailwind CSS
- Active Storage
- Solid Queue
- Solid Cache
- Solid Cable
- Minitest
- Capybara
- Docker
- GitHub Actions

---

## 5. Architecture

Domain:

User
SpotifyAccount
Track
Epic
Pick
Collection
CollectionEpic

Integration:

Spotify

Frontend:

Hotwire
Turbo
Stimulus
Tailwind

---

## 6. Domain Rules

### Epic

- start_time >= 0
- end_time > start_time
- end_time <= track duration when known
- Epic belongs to User
- Epic belongs to Track

### Pick

Unique:

user_id + epic_id

### CollectionEpic

Unique:

collection_id + epic_id

---

## 7. Spotify Rules

Spotify is an external integration.

Do not couple the domain directly to Spotify API clients.

Do not store Spotify audio.

Do not download Spotify tracks.

Do not circumvent Spotify playback restrictions.

Do not expose OAuth credentials or tokens to the client.

Any implementation involving playback must first
verify the current Spotify API capabilities and policies.

---

## 8. Privacy

Supported visibility:

- public
- private

Private content must not appear in public discovery.

---

## 9. Testing

Use Minitest.

Domain rules must have tests.

Important user flows must have integration/system tests.

Every new feature must include appropriate tests.

---

## 10. Database

Use PostgreSQL constraints where appropriate.

Use foreign keys.

Use unique indexes for uniqueness rules.

Avoid storing duplicated derived data unless justified.

---

## 11. Controllers

Controllers should remain thin.

Business logic belongs in the domain or appropriate application
services when necessary.

Do not create Service Objects simply for the sake of creating them.

---

## 12. Services

Services should be introduced only when they represent
a meaningful application operation or external integration.

Examples:

Spotify authentication
Spotify track search
Spotify token refresh

Do not create generic service abstractions.

---

## 13. Frontend

Mobile-first.

Use Hotwire wherever appropriate.

Use Stimulus for client-side behavior that cannot reasonably
be handled by server-rendered HTML/Turbo.

Do not build a SPA unless explicitly required.

---

## 14. Security

Follow Rails security conventions.

Validate all user input.

Authorize private resources.

Protect OAuth credentials.

Use CSRF protection.

Do not trust client-side timestamps or ownership information.

---

## 15. MVP Scope

The MVP includes:

- Spotify authentication
- music search
- Track representation
- Epic creation
- Epic playback where Spotify permits
- Collections
- Picks
- public profiles
- Discover
- Trending Epics

The MVP does NOT include:

- chat
- private messages
- comments
- followers
- advanced notifications
- AI recommendations
- marketplace
- monetization
- complex gamification

---

## 16. Development Rules

Before implementing a task:

1. Read CLAUDE.md.
2. Read ROADMAP.md.
3. Inspect the existing code.
4. Understand what already exists.
5. Do not overwrite working functionality unnecessarily.
6. Implement only the requested phase.
7. Write tests.
8. Run the relevant test suite.
9. Report what changed.

Do not advance to another roadmap phase automatically.

---

## 17. Definition of Done

A task is not complete until:

- implementation is complete;
- tests exist;
- tests pass;
- database changes are migrated;
- security considerations are addressed;
- no unrelated features were introduced.