require "rails_helper"

RSpec.describe Review, type: :model do
  it "is valid with valid attributes" do
    expect(build(:review)).to be_valid
  end

  it "requires a reviewable and a user" do
    expect(build(:review, reviewable: nil)).to be_invalid
    expect(build(:review, user: nil)).to be_invalid
  end

  it "requires a rating between 1 and 5" do
    expect(build(:review, rating: nil)).to be_invalid
    expect(build(:review, rating: 0)).to be_invalid
    expect(build(:review, rating: 6)).to be_invalid
    expect(build(:review, rating: 1)).to be_valid
    expect(build(:review, rating: 5)).to be_valid
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
      approved = create(:review, :approved)
      create(:review)
      create(:review, :rejected)

      expect(Review.approved).to contain_exactly(approved)
    end
  end

  describe "relation to reviewable" do
    it "works for rooms and services" do
      room = create(:room)
      service = create(:service)

      room_review = create(:review, :approved, reviewable: room)
      service_review = create(:review, :approved, reviewable: service)

      expect(room.approved_reviews).to include(room_review)
      expect(service.approved_reviews).to include(service_review)
      expect(room.approved_reviews).not_to include(service_review)
    end

    it "rejects an unsupported reviewable type" do
      expect(build(:review, reviewable_type: "User", reviewable_id: 1)).to be_invalid
      expect(build(:review, reviewable_type: "Room", reviewable_id: 999_999)).to be_invalid
    end
  end

  describe "uniqueness" do
    it "rejects a second review by the same user on the same object" do
      review = create(:review)
      duplicate = build(:review, user: review.user, reviewable: review.reviewable)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:reviewable]).to include("вы уже оставляли отзыв об этом объекте")
    end

    it "allows the same user to review different objects" do
      user = create(:user)
      create(:review, user: user, reviewable: create(:room))
      expect(build(:review, user: user, reviewable: create(:service))).to be_valid
    end

    it "enforces uniqueness at the database level" do
      existing = create(:review)
      duplicate = Review.new(user: existing.user, reviewable: existing.reviewable, rating: 5, body: "Ещё раз")

      expect(duplicate.save(validate: false)).to be(false)
      expect(duplicate.errors[:reviewable]).to include("вы уже оставляли отзыв об этом объекте")
    end
  end
end
