require "mail"
require "fileutils"

case ENV["APP_ENV"]
when "production"
  Mail.defaults do
    delivery_method :smtp,
      address: ENV.fetch("SMTP_ADDRESS", "localhost"),
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      domain: ENV.fetch("SMTP_DOMAIN", "hotel.local"),
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
  end
when "test"
  Mail.defaults { delivery_method :test }
else
  class FileMailDelivery
    def initialize(_settings = {})
    end

    def deliver!(mail)
      dir = File.join(APP_ROOT, "tmp", "mails")
      FileUtils.mkdir_p(dir)
      stamp = Time.now.strftime("%Y%m%d-%H%M%S")
      filename = "#{stamp}-#{mail.subject.to_s.gsub(/[^\w-]+/, "_").slice(0, 50)}.eml"
      File.write(File.join(dir, filename), mail.to_s)
    end
  end
  Mail.defaults { delivery_method FileMailDelivery }
end
