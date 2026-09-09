# Loads the cache/queue/cable schemas (db/cache_schema.rb and company).
#
# In production the four databases point at the same DATABASE_URL, and
# `db:prepare` only loads the schema of a database that does not exist yet. Since
# the primary had already created that database, the three remaining schemas were
# never applied — the app booted and broke on the first cache write with
# "No unique index found for key_hash".
#
# Idempotent: each schema uses create_table without force, so running it again on
# an already-prepared database does nothing.
namespace :db do
  desc "Load the Solid Cache/Queue/Cable schemas into the current database"
  task load_solid_schemas: :environment do
    # Each schema is identified by a sentinel table of its own, so running again
    # does not try to recreate anything.
    { "cache" => "solid_cache_entries",
      "queue" => "solid_queue_jobs",
      "cable" => "solid_cable_messages" }.each do |name, sentinel|
      path = Rails.root.join("db", "#{name}_schema.rb")
      next unless path.exist?

      if ActiveRecord::Base.connection.table_exists?(sentinel)
        puts "[solid] #{name}: ja carregado"
        next
      end

      puts "[solid] #{name}: carregando #{path.basename}"
      load path
    end
  end
end
