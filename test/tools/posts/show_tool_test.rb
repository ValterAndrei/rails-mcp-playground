require "test_helper"

class Posts::ShowToolTest < ActiveSupport::TestCase
  test "should show post details" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::ShowTool.call(id: post.id, server_context: {})

    assert_instance_of MCP::Tool::Response, response

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post encontrado com sucesso!", json["message"]
    assert_equal post.id, json["post"]["id"]
    assert_equal "Test Post", json["post"]["title"]
    assert_equal "Test Description", json["post"]["description"]
  end

  test "should include timestamps in response" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::ShowTool.call(id: post.id, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_not_nil json["post"]["created_at"]
    assert_not_nil json["post"]["updated_at"]
  end

  test "should return ISO8601 formatted timestamps" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::ShowTool.call(id: post.id, server_context: {})

    json = JSON.parse(response.content.first[:text])

    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json["post"]["created_at"])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json["post"]["updated_at"])
  end

  test "should handle post not found" do
    response = Posts::ShowTool.call(id: 99999, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "não encontrado"
    assert_includes json["message"], "99999"
  end

  test "should handle invalid id type" do
    response = Posts::ShowTool.call(id: "invalid", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "não encontrado"
    assert_includes json["message"], "invalid"
  end

  test "should handle unexpected errors gracefully" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    Post.stub :find, ->(_id) { raise StandardError.new("Database error") } do
      response = Posts::ShowTool.call(id: post.id, server_context: {})

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao buscar post"
      assert_includes json["message"], "Database error"
    end
  end

  test "should return complete post structure" do
    post = Post.create!(title: "Complete Test", description: "Complete Description")

    response = Posts::ShowTool.call(id: post.id, server_context: {})

    json = JSON.parse(response.content.first[:text])

    assert json["success"]
    assert json["post"].key?("id")
    assert json["post"].key?("title")
    assert json["post"].key?("description")
    assert json["post"].key?("created_at")
    assert json["post"].key?("updated_at")
  end
end
