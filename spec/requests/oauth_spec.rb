require "rails_helper"

RSpec.describe "User OAuth authentication", type: :request do
  def omniauth_auth(provider:, uid:, name:, email:)
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { name: name, email: email }
    )
  end

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe "VK callback" do
    it "creates a user from VK data and signs in" do
      OmniAuth.config.mock_auth[:vkontakte] = omniauth_auth(
        provider: "vkontakte", uid: "111", name: "Иван Иванов", email: "ivan.vk@example.com"
      )

      expect do
        get user_vkontakte_omniauth_callback_path
      end.to change(User, :count).by(1)

      user = User.last
      expect(user.provider).to eq("vkontakte")
      expect(user.uid).to eq("111")
      expect(user.email).to eq("ivan.vk@example.com")
      expect(user.full_name).to eq("Иван Иванов")
      expect(response).to redirect_to(bookings_path)
    end

    it "signs in an existing VK user without duplicating" do
      user = create(:user, provider: "vkontakte", uid: "111", email: "ivan.vk@example.com")
      OmniAuth.config.mock_auth[:vkontakte] = omniauth_auth(
        provider: "vkontakte", uid: "111", name: "Иван Иванов", email: "ivan.vk@example.com"
      )

      expect do
        get user_vkontakte_omniauth_callback_path
      end.not_to change(User, :count)

      expect(response).to redirect_to(bookings_path)
    end

    it "falls back to a placeholder email when VK does not provide one" do
      OmniAuth.config.mock_auth[:vkontakte] = omniauth_auth(
        provider: "vkontakte", uid: "222", name: "Пётр Петров", email: nil
      )

      get user_vkontakte_omniauth_callback_path

      user = User.last
      expect(user.email).to eq("vkontakte-222@example.com")
    end
  end

  describe "Yandex callback" do
    it "creates a user from Yandex data and signs in" do
      OmniAuth.config.mock_auth[:yandex] = omniauth_auth(
        provider: "yandex", uid: "333", name: "Анна Смирнова", email: "anna@yandex.ru"
      )

      expect do
        get user_yandex_omniauth_callback_path
      end.to change(User, :count).by(1)

      user = User.last
      expect(user.provider).to eq("yandex")
      expect(user.uid).to eq("333")
      expect(user.email).to eq("anna@yandex.ru")
    end
  end

  describe "User#from_omniauth" do
    it "generates a unique placeholder email per provider uid" do
      auth = omniauth_auth(provider: "vkontakte", uid: "444", name: "Олег", email: nil)
      user = User.from_omniauth(auth)

      expect(user.email).to eq("vkontakte-444@example.com")
      expect(user).to be_persisted
      expect(user.password).to be_present
    end
  end
end
