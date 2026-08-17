require "rack/utils"

module AppSupport
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = session["user_id"] && User.find_by(id: session["user_id"])
  end

  def notice
    @flash["notice"]
  end

  def alert
    @flash["alert"]
  end

  def csrf_token
    session["_csrf_token"] ||= SecureRandom.base64(32)
  end
  alias authenticity_token csrf_token

  def csrf_field
    %(<input type="hidden" name="authenticity_token" value="#{h(csrf_token)}">)
  end

  def csrf_meta_tag
    %(<meta name="csrf-token" content="#{h(csrf_token)}">)
  end

  def protect_from_forgery
    return if ENV["APP_ENV"] == "test"
    return unless request.post? || request.patch? || request.put? || request.delete?

    provided = params["authenticity_token"]
    return if provided && Rack::Utils.secure_compare(csrf_token, provided)

    halt 403, "Invalid authenticity token"
  end

  def require_admin!
    return if current_user&.admin?

    if current_user
      session["flash"] = { "alert" => "Доступ запрещён" }
      redirect root_path
    else
      session["flash"] = { "alert" => "Войдите, пожалуйста" }
      redirect new_user_session_path
    end
  end
end
