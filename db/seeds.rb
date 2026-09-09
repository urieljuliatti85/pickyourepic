# A development scenario: enough people for the app to make sense.
#
# Alone in the database there is nothing to Pick — you do not pick your own Epic
# (CLAUDE.md § Authorization), so a single user never sees a Pick button and the
# platform looks broken. These curators exist so that Discover holds other
# people's Epics, with Picks between them to give it something to order by.
#
# Idempotent: `find_or_create_by!` throughout, so running again duplicates nothing.
#
# Production is left out — these are invented people, and a real database gets its
# users from the Spotify OAuth flow, not from a seed.
if Rails.env.production?
  puts "seeds: nothing to do in production."
else
  # The tracks: with no Spotify configured there is no search, so the seed brings
  # the metadata ready. This is public catalogue data, not audio
  # (CLAUDE.md § Spotify policy constraints).
  #
  # The spotify_ids are REAL, and have to be: the play button builds
  # "spotify:track:#{spotify_id}" and hands it to the Web Playback SDK, so an
  # invented id gives an Epic that opens but will not play. They came from the
  # app's own search, with the name, duration and artwork Spotify returned.
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

  # One Epic per (user, track): that is what the unique index allows.
  #
  # The intervals fit inside each track's real duration: end_time > duration_ms
  # does not pass the Epic validation (CLAUDE.md §4).
  epics = [
    [ "mariana_riffs", "7MhEPacsDaXu33MGvT0WJ3", "The riff that opens it all", 15_000,  45_000, :public ],
    [ "mariana_riffs", "7vC957qXhk06DB5f90ei4s", "That beat right at the start", 0,  28_000, :public ],
    [ "joao_drops",    "4xshDuSn1JrMLTRi19GKBh", "The live drum fill",          60_000, 102_000, :public ],
    [ "joao_drops",    "6Ph8QwsRfZunN5e1GGBIqa", "The whole chorus",            52_000,  88_000, :public ],
    [ "bia_curadora",  "7GtTrm75kT8YnuyxywPVWg", "The moment that gives chills", 88_000, 121_000, :public ],
    # One private: only its owner sees it, and it can neither appear on Discover
    # nor receive a Pick — the case the visibility guards need to exercise.
    [ "bia_curadora",  "7MhEPacsDaXu33MGvT0WJ3", "Personal note",               30_000,  50_000, :private ]
  ].map do |username, track_id, title, start_time, end_time, visibility|
    user = User.find_or_create_by!(username: username)

    Epic.find_or_create_by!(user: user, track: tracks.fetch(track_id)) do |epic|
      epic.title = title
      epic.start_time = start_time
      epic.end_time = end_time
      epic.visibility = visibility
    end
  end

  # Crossed Picks, so Discover has something to order by: without them the page
  # falls back on the date tiebreak and the popularity ordering never shows.
  curators = User.where(username: %w[mariana_riffs joao_drops bia_curadora]).index_by(&:username)

  [
    [ "joao_drops",    0 ], [ "bia_curadora", 0 ],
    [ "mariana_riffs", 2 ], [ "bia_curadora", 2 ],
    [ "joao_drops",    4 ], [ "mariana_riffs", 3 ]
  ].each do |username, epic_index|
    epic = epics[epic_index]
    picker = curators.fetch(username)

    # The model's two rules, honored at the source so the seed does not lean on an
    # exception: no own Epic, no private Epic.
    next if epic.user_id == picker.id || epic.visibility_private?

    Pick.find_or_create_by!(user: picker, epic: epic)
  end

  # A public Collection with Epics from more than one person, the case the screen
  # needs to cover: someone else's offers a Pick, your own does not.
  collection = Collection.find_or_create_by!(user: curators.fetch("bia_curadora"),
                                             title: "Openings that work") do |c|
    c.description = "Openings that already give away the whole song."
    c.visibility = :public
  end

  [ epics[0], epics[2], epics[4] ].each_with_index do |epic, position|
    CollectionEpic.find_or_create_by!(collection: collection, epic: epic) do |ce|
      ce.position = position
    end
  end

  puts "seeds: #{User.count} users, #{Epic.count} Epics, #{Pick.count} Picks, " \
       "#{Collection.count} Collections."
end
