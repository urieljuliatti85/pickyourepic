class CreateCollectionEpics < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_epics do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :epic, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :collection_epics, [ :collection_id, :epic_id ], unique: true
    add_index :collection_epics, [ :collection_id, :position ]
  end
end
