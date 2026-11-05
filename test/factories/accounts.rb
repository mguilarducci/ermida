FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Condominium #{n}" }
  end
end
