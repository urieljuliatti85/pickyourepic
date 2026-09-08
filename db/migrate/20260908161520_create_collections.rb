class CreateCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :collections do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :description
      t.integer :visibility, default: 0, null: false

      t.timestamps
    end
  end
end
