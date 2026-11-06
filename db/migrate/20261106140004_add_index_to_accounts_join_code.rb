# Alone in its migration, since a concurrent build runs outside a transaction. A failed build leaves an invalid index
# behind, which StrongMigrations.remove_invalid_indexes drops before the rerun builds it again.
class AddIndexToAccountsJoinCode < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :accounts, :join_code, unique: true, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :accounts, :join_code, algorithm: :concurrently, if_exists: true
  end
end
