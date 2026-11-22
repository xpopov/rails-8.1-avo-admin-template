Avo.configure do |config|
  config.root_path = "/"
  config.app_name = "rails-8-avo"
  config.authenticate_with do
    if !rodauth.authenticated?
      redirect_to rodauth.login_path
    elsif !rodauth.rails_account&.admin?
      head :forbidden
    end
  end
  config.current_user_method do
    rodauth.rails_account
  end
end
