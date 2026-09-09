class CreatePicks < ActiveRecord::Migration[8.1]
  def change
    create_table :picks do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :epic, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # A user does not Pick the same Epic twice (CLAUDE.md § 6)
    add_index :picks, [ :user_id, :epic_id ], unique: true
  end
end
