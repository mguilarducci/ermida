# The column starts nullable, with a NOT NULL check that skips existing rows, so adding it locks nothing. The next
# migrations fill it, then make it NOT NULL.
class AddJoinCodeToAccounts < ActiveRecord::Migration[8.1]
  def up
    add_column :accounts, :join_code, :string, if_not_exists: true
    add_check_constraint :accounts, "join_code IS NOT NULL", name: "accounts_join_code_null", validate: false,
      if_not_exists: true
  end

  def down
    remove_check_constraint :accounts, name: "accounts_join_code_null", if_exists: true
    remove_column :accounts, :join_code, if_exists: true
  end
end
