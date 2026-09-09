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
  #
  # Os spotify_id sao REAIS, e precisam ser: o botao de play monta
  # "spotify:track:#{spotify_id}" e entrega ao Web Playback SDK, entao um id
  # inventado da um Epic que abre mas nao toca. Vieram da busca da propria
  # app, com nome, duracao e capa como o Spotify os devolveu.
  tracks = [
    { spotify_id: "7MhEPacsDaXu33MGvT0WJ3", name: "Lake Bodom",
      artist_name: "Children Of Bodom", duration_ms: 241_800,
      album_artwork_url: "https://i.scdn.co/image/ab67616d0000485128e69c33cab73d9eacf92576" },
    { spotify_id: "7vC957qXhk06DB5f90ei4s", name: "I´m Shipping Up To Boston",
      artist_name: "Children Of Bodom", duration_ms: 170_253,
      album_artwork_url: "https://i.scdn.co/image/ab67616d00004851127c9e3be534edd650c450d4" },
    { spotify_id: "4xshDuSn1JrMLTRi19GKBh", name: "Lake Bodom - Live",
      artist_name: "Children Of Bodom", duration_ms: 249_453,
      album_artwork_url: "https://i.scdn.co/image/ab67616d00004851e5ae646588f9a8af78e8d59f" },
    { spotify_id: "6Ph8QwsRfZunN5e1GGBIqa", name: "Hurt",
      artist_name: "Oliver Tree", duration_ms: 145_147,
      album_artwork_url: "https://i.scdn.co/image/ab67616d00004851c1bdf5564ed647ab6cb12f4b" },
    { spotify_id: "7GtTrm75kT8YnuyxywPVWg", name: "Lake Bodom - Final Show in Helsinki Ice Hall 2019",
      artist_name: "Children Of Bodom", duration_ms: 243_560,
      album_artwork_url: "https://i.scdn.co/image/ab67616d00004851aeeb9916152ce66db30a073a" }
  ].each_with_object({}) do |attrs, index|
    track = Track.find_or_create_by!(spotify_id: attrs[:spotify_id]) do |t|
      t.assign_attributes(attrs.except(:spotify_id))
    end
    index[attrs[:spotify_id]] = track
  end

  # Um Epic por (user, track): e o que o indice unico permite.
  #
  # Os intervalos cabem na duracao real de cada faixa: end_time > duration_ms
  # nao passa da validacao do Epic (CLAUDE.md §4).
  epics = [
    [ "mariana_riffs", "7MhEPacsDaXu33MGvT0WJ3", "O riff que abre tudo",      15_000,  45_000, :public ],
    [ "mariana_riffs", "7vC957qXhk06DB5f90ei4s", "Essa batida no comeco",           0,  28_000, :public ],
    [ "joao_drops",    "4xshDuSn1JrMLTRi19GKBh", "A virada ao vivo",          60_000, 102_000, :public ],
    [ "joao_drops",    "6Ph8QwsRfZunN5e1GGBIqa", "O refrao inteiro",          52_000,  88_000, :public ],
    [ "bia_curadora",  "7GtTrm75kT8YnuyxywPVWg", "O momento que arrepia",     88_000, 121_000, :public ],
    # Um privado: so a dona o ve, e ele nao pode aparecer no Discover nem
    # receber Pick — o caso que as guardas de visibilidade precisam exercitar.
    [ "bia_curadora",  "7MhEPacsDaXu33MGvT0WJ3", "Anotacao pessoal",          30_000,  50_000, :private ]
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
