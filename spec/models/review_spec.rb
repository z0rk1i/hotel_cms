require "rails_helper"

RSpec.describe Review, type: :model do
  it "is valid with valid attributes" do
    user = create(:user)
    room = create(:room)
    give_user_a_stay!(user, room)
    expect(build(:review, user: user, reviewable: room)).to be_valid
  end

  it "requires a reviewable and a user" do
    expect(build(:review, reviewable: nil)).to be_invalid
    expect(build(:review, user: nil)).to be_invalid
  end

  it "requires a rating between 1 and 5" do
    expect(build(:review, rating: nil)).to be_invalid
    expect(build(:review, rating: 0)).to be_invalid
    expect(build(:review, rating: 6)).to be_invalid

    user = create(:user)
    room = create(:room)
    give_user_a_stay!(user, room)
    expect(build(:review, user: user, reviewable: room, rating: 1)).to be_valid
    expect(build(:review, user: user, reviewable: room, rating: 5)).to be_valid
  end

  it "requires a body" do
    expect(build(:review, body: nil)).to be_invalid
    expect(build(:review, body: "")).to be_invalid
  end

  it "defaults to pending" do
    expect(build(:review)).to be_pending
  end

  describe ".approved" do
    it "includes only approved reviews" do
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)
      approved = create(:review, :approved, user: user, reviewable: room)

      other_user = create(:user)
      give_user_a_stay!(other_user, room)
      create(:review, user: other_user, reviewable: room)

      third_user = create(:user)
      give_user_a_stay!(third_user, room)
      create(:review, :rejected, user: third_user, reviewable: room)

      expect(Review.approved).to contain_exactly(approved)
    end
  end

  describe "relation to reviewable" do
    it "works for rooms and services" do
      room = create(:room)
      service = create(:service)
      room_user = create(:user)
      service_user = create(:user)
      give_user_a_stay!(room_user, room)
      give_user_a_stay!(service_user, service)

      room_review = create(:review, :approved, reviewable: room, user: room_user)
      service_review = create(:review, :approved, reviewable: service, user: service_user)

      expect(room.approved_reviews).to include(room_review)
      expect(service.approved_reviews).to include(service_review)
      expect(room.approved_reviews).not_to include(service_review)
    end

    it "rejects an unsupported reviewable type" do
      expect(build(:review, reviewable_type: "User", reviewable_id: 1)).to be_invalid
      expect(build(:review, reviewable_type: "Room", reviewable_id: 999_999)).to be_invalid
    end
  end

  describe "completed stay requirement" do
    it "rejects a review for a room the user never booked" do
      user = create(:user)
      room = create(:room)
      review = build(:review, user: user, reviewable: room)

      expect(review).to be_invalid
      expect(review.errors[:base]).to include("оставить отзыв можно только после проживания или заказа услуги")
    end

    it "allows a review after a checked_out stay" do
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)
      expect(build(:review, user: user, reviewable: room)).to be_valid
    end

    it "allows a review during a checked_in stay" do
      user = create(:user)
      room = create(:room)
      create(:booking, :checked_in, user: user, room: room,
             check_in: Date.current, check_out: Date.current + 2)
      expect(build(:review, user: user, reviewable: room)).to be_valid
    end

    it "rejects a service review without a confirmed order" do
      user = create(:user)
      service = create(:service)
      expect(build(:review, user: user, reviewable: service)).to be_invalid
    end

    it "allows a service review with a confirmed order" do
      user = create(:user)
      service = create(:service)
      give_user_a_stay!(user, service)
      expect(build(:review, user: user, reviewable: service)).to be_valid
    end
  end

  describe "uniqueness" do
    it "rejects a second review by the same user on the same object" do
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)
      review = create(:review, user: user, reviewable: room)
      duplicate = build(:review, user: user, reviewable: room)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:reviewable]).to include("вы уже оставляли отзыв об этом объекте")
    end

    it "allows the same user to review different objects" do
      user = create(:user)
      room = create(:room)
      service = create(:service)
      give_user_a_stay!(user, room)
      give_user_a_stay!(user, service)
      create(:review, user: user, reviewable: room)
      expect(build(:review, user: user, reviewable: service)).to be_valid
    end

    it "enforces uniqueness at the database level" do
      user = create(:user)
      room = create(:room)
      give_user_a_stay!(user, room)
      existing = create(:review, user: user, reviewable: room)
      duplicate = Review.new(user: existing.user, reviewable: existing.reviewable, rating: 5, body: "Ещё раз")

      expect(duplicate.save(validate: false)).to be(false)
      expect(duplicate.errors[:reviewable]).to include("вы уже оставляли отзыв об этом объекте")
    end
  end
end
