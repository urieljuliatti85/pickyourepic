class CreateSpotifyAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :spotify_accounts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :spotify_uid, null: false
      t.string :email
      t.string :product

      # Criptografados em repouso via Active Record Encryption (CLAUDE.md §11).
      # text porque o ciphertext é bem maior que o token original.
      t.text :access_token
      t.text :refresh_token

      t.datetime :expires_at

      t.timestamps
    end

    add_index :spotify_accounts, :spotify_uid, unique: true
  end
end
