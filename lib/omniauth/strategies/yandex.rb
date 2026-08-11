module OmniAuth
  module Strategies
    class Yandex < OmniAuth::Strategies::OAuth2
      option :name, "yandex"
      option :scope, "login:info login:email"

      option :client_options, {
        site: "https://oauth.yandex.ru",
        authorize_url: "https://oauth.yandex.ru/authorize",
        token_url: "https://oauth.yandex.ru/token"
      }

      uid { raw_info["id"].to_s }

      info do
        {
          email: raw_info["default_email"].presence || raw_info["emails"]&.first,
          first_name: raw_info["first_name"],
          last_name: raw_info["last_name"],
          name: raw_info["real_name"].presence || raw_info["display_name"].presence,
          image: avatar_url
        }
      end

      extra { { raw_info: raw_info } }

      private

      def avatar_url
        id = raw_info["default_avatar_id"]
        return nil if id.blank?

        "https://avatars.yandex.net/get-yapic/#{id}/islands-200"
      end

      def raw_info
        @raw_info ||= begin
          response = access_token.get("https://login.yandex.ru/info",
            headers: { "Authorization" => "OAuth #{access_token.token}" })
          JSON.parse(response.body)
        end
      end
    end
  end
end
