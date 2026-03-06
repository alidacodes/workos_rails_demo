require "workos"

WorkOS.configure do |config|
  config.key = ENV.fetch("WORKOS_KEY", nil)
  config.timeout = 12 # seconds, defult is 60 but Rack is 15, being more aggressive here to avoid Rack timeouts
end