class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  route do |r|
    rodauth.load_memory # autologin remembered users

    r.rodauth # route rodauth requests

    r.on "sidekiq" do
      rodauth.require_authentication
      r.halt [ 403, { "content-type" => "text/plain" }, [ "Forbidden" ] ] unless rodauth.rails_account.admin?
    end

    # ==> Secondary configurations
    # r.rodauth(:admin) # route admin rodauth requests
  end
end
