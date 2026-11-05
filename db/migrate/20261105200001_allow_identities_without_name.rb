class AllowIdentitiesWithoutName < ActiveRecord::Migration[8.1]
  def change
    change_column_null :identities, :name, true
  end
end
