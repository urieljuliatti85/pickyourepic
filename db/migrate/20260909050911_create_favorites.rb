class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :epic, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # One Favorite per user per Epic. The index, not just the validation, is what
    # settles two simultaneous clicks on the same button.
    add_index :favorites, [ :user_id, :epic_id ], unique: true
  end
end
