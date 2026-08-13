require "rails_helper"

RSpec.describe "Admin users", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/users" do
    it "lists users" do
      user = create(:user, full_name: "Иван Петров")
      get admin_users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Иван Петров")
    end

    it "filters to guests only" do
      admin_user = create(:user, :admin, full_name: "Админ", email: "boss@example.org")
      guest = create(:user, full_name: "Гость")

      get admin_users_path, params: { type: "guests" }
      expect(response.body).to include("Гость")
      expect(response.body).not_to include("boss@example.org")
    end

    it "filters to VIP" do
      vip = create(:user, :vip, full_name: "ВИП")
      create(:user, full_name: "Обычный")

      get admin_users_path, params: { vip: "1" }
      expect(response.body).to include("ВИП")
      expect(response.body).not_to include("Обычный")
    end
  end

  describe "GET /admin/users/:id" do
    it "shows the user and their stays" do
      user = create(:user, full_name: "Иван Петров")
      stay = create(:stay, :checked_out, user: user)

      get admin_user_path(user)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.full_name)
    end
  end

  describe "PATCH /admin/users/:id/toggle_vip" do
    it "toggles the VIP flag" do
      user = create(:user)
      patch toggle_vip_admin_user_path(user)
      expect(user.reload.is_vip).to be(true)
      patch toggle_vip_admin_user_path(user)
      expect(user.reload.is_vip).to be(false)
    end
  end

  describe "POST /admin/users/:id/merge_into" do
    it "merges the source user into the target" do
      source = create(:user, full_name: "Дубль")
      target = create(:user, full_name: "Оригинал")
      stay = create(:stay, user: source)

      post merge_into_admin_user_path(source), params: { target_user_id: target.id }

      expect(stay.reload.user).to eq(target)
      expect(User.exists?(source.id)).to be(false)
      expect(response).to redirect_to(admin_user_path(target))
    end
  end
end
