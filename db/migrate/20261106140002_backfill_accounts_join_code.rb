# Gives each existing account its own join code, in the format Account::JoinCode generates.
class BackfillAccountsJoinCode < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # The app's Account validates the code against a unique index that does not exist yet.
  class Account < ActiveRecord::Base
    self.table_name = "accounts"
  end

  def up
    Account.where(join_code: nil).find_each do |account|
      account.update_columns(join_code: SecureRandom.base58(12).scan(/.{4}/).join("-"))
    end

    if Account.where(join_code: nil).exists?
      raise "Some accounts still have no join code"
    end
  end

  # Rolling back AddJoinCodeToAccounts drops the codes with the column.
  def down
  end
end
