require "haml"
require "tilt"

class BookingMailer
  FROM = ENV.fetch("MAILER_FROM", "Hotel CMS <no-reply@hotel.local>")

  def self.confirmation(stay)
    view = MailView.new(stay, stay.user)
    html = view.render("booking_mailer/confirmation")
    text = view.render("booking_mailer/confirmation.text")

    Mail.new do
      from FROM
      to stay.user.email.to_s
      subject "Бронь №#{stay.id} создана — ожидает подтверждения"
      text_part { body text }
      html_part do
        content_type "text/html; charset=UTF-8"
        body html
      end
    end.deliver
  end

  # Renders HAML mail templates with @stay/@user instance vars and view helpers.
  class MailView
    def initialize(stay, user)
      @stay = stay
      @user = user
    end

    def render(template)
      path = File.join(APP_ROOT, "app", "views", "#{template}.haml")
      Tilt::HamlTemplate.new(path) { File.read(path) }.render(self)
    end

    def l(date, format: :long)
      I18n.l(date, format: format)
    end

    def number_to_currency(amount, **_opts)
      money(amount)
    end

    def money(amount)
      ApplicationHelper.money(amount)
    end

    def link_to(text, url)
      %(<a href="#{url}">#{text}</a>)
    end

    def account_url(phone:)
      host = ENV.fetch("APP_HOST", "localhost:3000")
      "http://#{host}/account?phone=#{Rack::Utils.escape(phone.to_s)}"
    end
  end
end
