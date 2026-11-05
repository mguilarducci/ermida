class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: -> { "uuidv7()" } do |t|
      # The unique index below starts with account_id, so it serves lookups by account.
      t.references :account, null: false, foreign_key: true, type: :uuid, index: false
      t.references :identity, foreign_key: true, type: :uuid
      t.string :role, null: false, default: "member"
      t.boolean :active, null: false, default: true
      t.datetime :verified_at

      t.timestamps
    end
    # Postgres treats NULLs as distinct here, so an account can hold many users without an identity.
    add_index :users, [:account_id, :identity_id], unique: true
  end
end
