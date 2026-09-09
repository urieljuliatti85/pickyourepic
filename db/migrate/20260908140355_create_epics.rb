class CreateEpics < ActiveRecord::Migration[8.1]
  def change
    create_table :epics do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :track, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :description
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.integer :visibility, default: 0, null: false

      t.timestamps
    end

    # Constraints per CLAUDE.md § 6
    add_check_constraint :epics, "start_time >= 0", name: "epics_start_time_non_negative"
    add_check_constraint :epics, "end_time > start_time", name: "epics_end_time_greater_than_start"

    # A user creates only 1 Epic per Track
    add_index :epics, [ :user_id, :track_id ], unique: true
  end
end
