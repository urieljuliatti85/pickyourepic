class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.string :spotify_id, null: false
      t.string :name, null: false
      t.string :artist_name, null: false
      t.string :album_name
      t.string :album_artwork_url
      t.integer :duration_ms, null: false

      t.timestamps
    end

    add_index :tracks, :spotify_id, unique: true
    add_check_constraint :tracks, "duration_ms > 0", name: "tracks_duration_positive"
  end
end
