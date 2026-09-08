class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :display_name
      t.string :avatar_url
      t.text :bio
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end

    add_index :users, "lower(username)", unique: true, name: "index_users_on_lower_username"
  end
end
