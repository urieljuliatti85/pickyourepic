# Cenario de desenvolvimento: gente suficiente para o app fazer sentido.
#
# Sozinho no banco nao ha o que Pickar — nao se pica o proprio Epic
# (CLAUDE.md § Authorization), entao um unico usuario nunca ve um botao de
# Pick e a plataforma parece quebrada. Estes curadores existem para que o
# Discover tenha Epics de outras pessoas, com Picks entre si para haver o que
# ordenar.
#
# Idempotente: `find_or_create_by!` em tudo, entao rodar de novo nao duplica.
#
# Producao fica de fora — sao pessoas inventadas, e o banco real ganha seus
# usuarios pelo OAuth do Spotify, nao por seed.
if Rails.env.production?
  puts "seeds: nada a fazer em producao."
else
  # As faixas: sem Spotify configurado nao ha busca, entao o seed traz os
  # metadados prontos. Sao dados publicos de catalogo, nao audio
  # (CLAUDE.md § Spotify policy constraints).
  tracks = [
    { spotify_id: "seed_track_01", name: "Lake Bodom",
      artist_name: "Children Of Bodom", duration_ms: 241_800 },
    { spotify_id: "seed_track_02", name: "I'm Shipping Up To Boston",
      artist_name: "Dropkick Murphys", duration_ms: 170_253 },
    { spotify_id: "seed_track_03", name: "Innerbloom",
      artist_name: "RÜFÜS DU SOL", duration_ms: 559_000 },
    { spotify_id: "seed_track_04", name: "Everlong",
      artist_name: "Foo Fighters", duration_ms: 250_546 },
    { spotify_id: "seed_track_05", name: "Teardrop",
      artist_name: "Massive Attack", duration_ms: 330_866 }
  ].each_with_object({}) do |attrs, index|
    track = Track.find_or_create_by!(spotify_id: attrs[:spotify_id]) do |t|
      t.assign_attributes(attrs.except(:spotify_id))
    end
    index[attrs[:spotify_id]] = track
  end

  # Um Epic por (user, track): e o que o indice unico permite.
  epics = [
    [ "mariana_riffs", "seed_track_01", "O riff que abre tudo",       15_000,  45_000, :public ],
    [ "mariana_riffs", "seed_track_02", "Essa batida no comeco",           0,  28_000, :public ],
    [ "joao_drops",    "seed_track_03", "O drop que vale a musica",  240_000, 288_000, :public ],
    [ "joao_drops",    "seed_track_04", "Solo inteiro, sem cortes",  120_000, 168_000, :public ],
    [ "bia_curadora",  "seed_track_05", "O momento que arrepia",      88_000, 121_000, :public ],
    # Um privado: so a dona o ve, e ele nao pode aparecer no Discover nem
    # receber Pick — o caso que as guardas de visibilidade precisam exercitar.
    [ "bia_curadora",  "seed_track_01", "Anotacao pessoal",           30_000,  50_000, :private ]
  ].map do |username, track_id, title, start_time, end_time, visibility|
    user = User.find_or_create_by!(username: username)

    Epic.find_or_create_by!(user: user, track: tracks.fetch(track_id)) do |epic|
      epic.title = title
      epic.start_time = start_time
      epic.end_time = end_time
      epic.visibility = visibility
    end
  end

  # Picks cruzados, para o Discover ter o que ordenar: sem eles a home cai no
  # desempate por data e a ordenacao por popularidade nao aparece.
  curators = User.where(username: %w[mariana_riffs joao_drops bia_curadora]).index_by(&:username)

  [
    [ "joao_drops",    0 ], [ "bia_curadora", 0 ],
    [ "mariana_riffs", 2 ], [ "bia_curadora", 2 ],
    [ "joao_drops",    4 ], [ "mariana_riffs", 3 ]
  ].each do |username, epic_index|
    epic = epics[epic_index]
    picker = curators.fetch(username)

    # As duas regras do model, respeitadas na origem para o seed nao depender
    # de excecao: nada de Epic proprio, nada de Epic privado.
    next if epic.user_id == picker.id || epic.visibility_private?

    Pick.find_or_create_by!(user: picker, epic: epic)
  end

  # Uma Collection publica com Epics de mais de uma pessoa, que e o caso que a
  # tela precisa cobrir: a de outra pessoa oferece Pick, a propria nao.
  collection = Collection.find_or_create_by!(user: curators.fetch("bia_curadora"),
                                             title: "Aberturas que funcionam") do |c|
    c.description = "Comecos que ja entregam a musica inteira."
    c.visibility = :public
  end

  [ epics[0], epics[2], epics[4] ].each_with_index do |epic, position|
    CollectionEpic.find_or_create_by!(collection: collection, epic: epic) do |ce|
      ce.position = position
    end
  end

  puts "seeds: #{User.count} usuarios, #{Epic.count} Epics, #{Pick.count} Picks, " \
       "#{Collection.count} Collections."
end
