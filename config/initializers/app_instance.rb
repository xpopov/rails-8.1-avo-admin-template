Rails.application.config.to_prepare do
  $app = AppInstance.from_environment
  Rails.configuration.x.app_instance = $app
end
