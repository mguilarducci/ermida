class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.string :email_address, null: false
      t.string :name, null: false
      t.boolean :staff, null: false, default: false

      t.timestamps
    end
    add_index :identities, :email_address, unique: true
  end
end
