# frozen_string_literal: true

# Create the azure_login_nonces table in the database.
class CreateAzureLoginNonces < ActiveRecord::Migration[6.1]
  def change
    create_table :azure_login_nonces do |t|
      t.string :nonce_value, null: false

      t.index :nonce_value, unique: true

      t.timestamps
    end
  end
end
