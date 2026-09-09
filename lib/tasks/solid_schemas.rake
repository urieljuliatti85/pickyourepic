# Carrega os schemas de cache/queue/cable (db/cache_schema.rb e companhia).
#
# Em producao os quatro bancos apontam para o mesmo DATABASE_URL, e `db:prepare`
# so carrega o schema de um banco que ainda nao existe. Como o primario ja criou
# esse banco, os tres schemas restantes nunca eram aplicados — a app subia e
# quebrava na primeira escrita de cache com "No unique index found for key_hash".
#
# Idempotente: cada schema usa create_table sem force, entao rodar de novo em
# um banco ja preparado nao faz nada.
namespace :db do
  desc "Load the Solid Cache/Queue/Cable schemas into the current database"
  task load_solid_schemas: :environment do
    # Cada schema e identificado por uma tabela sentinela sua, para que rodar de
    # novo nao tente recriar nada.
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
