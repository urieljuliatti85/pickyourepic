class CreateCollectionEpics < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_epics do |t|
      t.references :collection, null: false, foreign_key: { on_delete: :cascade }
      t.references :epic, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    # Unique index to prevent duplicate epics in same collection
    add_index :collection_epics, [ :collection_id, :epic_id ], unique: true
  end
end
