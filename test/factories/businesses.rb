FactoryBot.define do
  factory :business do
    sequence(:name) { |n| "Business #{n}" }
    description { "A neighborhood business." }
  end
end
