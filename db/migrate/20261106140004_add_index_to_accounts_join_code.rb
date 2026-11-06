# Alone in its migration: a failed concurrent build leaves an invalid index behind, and a rerun of this migration
# alone stays clean.
class AddIndexToAccountsJoinCode < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :accounts, :join_code, unique: true, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :accounts, :join_code, algorithm: :concurrently, if_exists: true
  end
end
