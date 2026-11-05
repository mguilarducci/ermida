class Session < ApplicationRecord
  db_belongs_to :identity
end
