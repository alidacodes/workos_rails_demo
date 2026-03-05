require "workos"

WorkOS.configure do |config|
  config.key = ENV.fetch("WORKOS_KEY", nil)
end