FactoryBot.define do
  factory :gallery_image do
    title { Faker::Lorem.sentence(word_count: 3) }

    after(:build) do |gallery_image|
      gallery_image.image.attach(
        io: StringIO.new(Rails.root.join("spec/fixtures/files/placeholder.jpg").read),
        filename: "placeholder.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
