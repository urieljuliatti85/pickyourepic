class CreateEpics < ActiveRecord::Migration[8.1]
  def change
    create_table :epics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.integer :start_ms, null: false
      t.integer :end_ms, null: false
      t.string :title
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.integer :picks_count, null: false, default: 0
      t.integer :plays_count, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :epics, "start_ms >= 0", name: "epics_start_non_negative"
    add_check_constraint :epics, "end_ms > start_ms", name: "epics_end_after_start"
    add_check_constraint :epics, "end_ms - start_ms <= 30000", name: "epics_max_duration"
    add_check_constraint :epics, "picks_count >= 0", name: "epics_picks_count_non_negative"
    add_check_constraint :epics, "plays_count >= 0", name: "epics_plays_count_non_negative"

    add_index :epics, [ :visibility, :picks_count ]
    add_index :epics, :created_at
  end
end
