class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :identity, null: false, foreign_key: true, type: :uuid
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
