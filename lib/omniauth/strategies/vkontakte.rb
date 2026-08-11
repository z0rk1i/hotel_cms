module OmniAuth
  module Strategies
    class Vkontakte < OmniAuth::Strategies::OAuth2
      option :name, "vkontakte"
      option :scope, "email"

      option :client_options, {
        site: "https://oauth.vk.com",
        authorize_url: "https://oauth.vk.com/authorize",
        token_url: "https://oauth.vk.com/access_token"
      }

      uid { raw_info["id"].to_s }

      info do
        {
          email: access_token.params["email"],
          first_name: raw_info["first_name"],
          last_name: raw_info["last_name"],
          name: [ raw_info["first_name"], raw_info["last_name"] ].reject(&:blank?).join(" "),
          image: raw_info["photo_200"]
        }
      end

      extra { { raw_info: raw_info } }

      private

      def raw_info
        @raw_info ||= begin
          response = access_token.get("https://api.vk.com/method/users.get",
            params: { v: "5.131", fields: "photo_200" }).parsed
          (response["response"] || []).first || {}
        end
      end
    end
  end
end
