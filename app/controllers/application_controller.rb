class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    if Rails.env.production?
      { locale: I18n.locale, host: ENV["DOMAIN"] }
    else
      { locale: I18n.locale, host: "localhost:3000" }
    end
  end
end
