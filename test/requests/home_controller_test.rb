require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns status ok and expected json structure" do
    get root_url, as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "ok", body["status"]
    assert_includes [ "test", "development", "production" ], body["env"]
    assert body["time"].present?, "expected response to include time"
  end
end
