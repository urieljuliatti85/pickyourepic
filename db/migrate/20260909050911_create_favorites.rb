class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :epic, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # Um Favorite por user por Epic. O indice, e nao so a validacao, e o que
    # resolve dois cliques simultaneos no mesmo botao.
    add_index :favorites, [ :user_id, :epic_id ], unique: true
  end
end
