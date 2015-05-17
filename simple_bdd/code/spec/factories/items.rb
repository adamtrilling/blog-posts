FactoryGirl.define do
  factory :item do
    text { Faker::Lorem.sentence }
    completed false
  end
end
