require "webmock/rspec"

# Observe Ruby HTTP calls without blocking live integrations. Individual specs can still stub external boundaries.
WebMock.allow_net_connect!(allow_localhost: true)
