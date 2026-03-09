require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WorkosRailsDemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.

    # Store sessions server-side in solid_cache; cookie holds only an opaque encrypted ID.
    # expire_after is set slightly longer than session_expiry (1.hour in the adapter)
    # so check_session_expiry always fires first with a meaningful UX message
    # before the cache TTL silently evicts the entry as a hard backstop.
    config.session_store :cache_store, expire_after: 70.minutes
  end
end
