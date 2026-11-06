class MakeAccountsJoinCodeNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :accounts, name: "accounts_join_code_null"
    change_column_null :accounts, :join_code, false
    remove_check_constraint :accounts, name: "accounts_join_code_null"
  end

  def down
    change_column_null :accounts, :join_code, true
    add_check_constraint :accounts, "join_code IS NOT NULL", name: "accounts_join_code_null", validate: false,
      if_not_exists: true
  end
end
