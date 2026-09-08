# Migrations planejadas — próxima fase

Estas migrations definem o domínio (User, SpotifyAccount, Track, Epic, Pick,
Collection, CollectionEpic) conforme CLAUDE.md §5 e §12, incluindo as constraints
do PostgreSQL listadas na tabela de §12.

Elas **não fazem parte da fase de fundação** e por isso estão fora de `db/migrate`.
Ao iniciar a fase de domínio, mover de volta:

```bash
mv db/planned_migrations/*.rb db/migrate/ && bin/rails db:migrate
```
