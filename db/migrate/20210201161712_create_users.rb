# frozen_string_literal: true

# Create the users table in the database.
class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :azure_id, null: false
      t.string :email, null: false
      t.string :full_name, null: false
      t.string :roles, null: false, array: true

      t.index :azure_id, unique: true

      t.timestamps
    end
  end
end
