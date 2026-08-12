require "rails_helper"

RSpec.describe "Admin reviews", type: :request do
  let(:admin) { create(:administrator) }

  before { sign_in admin }

  def create_review(*traits, **overrides)
    user = create(:user)
    room = create(:room)
    give_user_a_stay!(user, room)
    create(:review, *traits, user: user, reviewable: room, **overrides)
  end

  describe "GET /admin/reviews" do
    it "lists reviews with author and object" do
      review = create_review(body: "Шикарный номер")

      get admin_reviews_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Шикарный номер")
      expect(response.body).to include(review.user.full_name)
    end

    it "filters by status" do
      approved = create_review(:approved, body: "Одобренный отзыв")
      create_review(body: "Ожидает")

      get admin_reviews_path(status: "approved")
      expect(response.body).to include("Одобренный отзыв")
      expect(response.body).not_to include("Ожидает")
    end
  end

  describe "PATCH /admin/reviews/:id/approve" do
    it "approves a pending review" do
      review = create_review
      patch approve_admin_review_path(review)
      expect(review.reload).to be_approved
      expect(response).to redirect_to(admin_reviews_path)
    end
  end

  describe "PATCH /admin/reviews/:id/reject" do
    it "rejects a pending review" do
      review = create_review
      patch reject_admin_review_path(review)
      expect(review.reload).to be_rejected
    end
  end

  describe "DELETE /admin/reviews/:id" do
    it "deletes a review" do
      review = create_review
      expect { delete admin_review_path(review) }.to change(Review, :count).by(-1)
      expect(response).to redirect_to(admin_reviews_path)
    end
  end

  describe "authentication" do
    it "requires an administrator" do
      sign_out admin
      get admin_reviews_path
      expect(response).to redirect_to(new_administrator_session_path)
    end
  end
end
