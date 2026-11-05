class CreateMagicLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :magic_links, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :identity, null: false, foreign_key: true, type: :uuid
      t.string :code, null: false, index: {unique: true}
      t.string :purpose, null: false, default: "sign_in"
      t.datetime :expires_at, null: false, index: true

      t.timestamps
    end
  end
end
