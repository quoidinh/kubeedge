require "test_helper"

class HealthCheckControllerTest < ActionDispatch::IntegrationTest
  test "should get healthcheck" do
    get health_check_healthcheck_url
    assert_response :success
  end
end
