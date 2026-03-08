ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "ostruct"

# Default WorkOS env vars for test — real CI secrets override these via ENV
ENV["WORKOS_API_KEY"]         ||= "test_api_key"
ENV["WORKOS_CLIENT_ID"]       ||= "test_client_id"
ENV["WORKOS_ORGANIZATION_ID"] ||= "test_org_id"
ENV["WORKOS_REDIRECT_URI"]    ||= "http://localhost:3000/auth/callback"

require_relative "../app/lib/adapters/workos_api_adapter"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    private

    # Temporarily replaces a singleton method on +object+ with a stub for the
    # duration of the block. If +value_or_callable+ responds to #call it is
    # invoked with the original arguments; otherwise it is returned directly.
    def stub_method(object, method_name, value_or_callable)
      original = object.method(method_name)
      object.define_singleton_method(method_name) do |*args, **kwargs|
        if value_or_callable.respond_to?(:call)
          value_or_callable.call(*args, **kwargs)
        else
          value_or_callable
        end
      end
      yield
    ensure
      object.define_singleton_method(method_name, &original)
    end
  end
end

class ActionDispatch::IntegrationTest
  private

  # Simulates a successful SSO login by stubbing WorkosApiAdapter.callback
  # and calling the real callback action, which populates the Rails session.
  def login
    mock_profile = OpenStruct.new(
      id: "user_123",
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    )
    mock_result = { profile: mock_profile, expires_at: (Time.now + 1.hour).to_i }
    stub_method(WorkosApiAdapter, :callback, mock_result) do
      get auth_callback_url, params: { code: "test_code" }
    end
  end
end
