# Sign-up creates the identity when the email is typed and asks for the name only after the code.
class AllowIdentitiesWithoutName < ActiveRecord::Migration[8.1]
  def change
    change_column_null :identities, :name, true
  end
end
