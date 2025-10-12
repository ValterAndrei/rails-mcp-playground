require "test_helper"

class Posts::ShowToolTest < ActiveSupport::TestCase
  test "should show post details" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::ShowTool.call(id: post.id, server_context: {})

    assert_instance_of MCP::Tool::Response, response
    text = response.content.first[:text]
    assert_includes text, "Post encontrado"
    assert_includes text, post.id.to_s
    assert_includes text, "Test Post"
    assert_includes text, "Test Description"
  end

  test "should include timestamps in response" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::ShowTool.call(id: post.id, server_context: {})

    text = response.content.first[:text]
    assert_includes text, "created_at"
    assert_includes text, "updated_at"
  end

  test "should handle post not found" do
    response = Posts::ShowTool.call(id: 99999, server_context: {})

    assert_includes response.content.first[:text], "não encontrado"
  end

  test "should handle invalid id type" do
    response = Posts::ShowTool.call(id: "invalid", server_context: {})

    assert_includes response.content.first[:text], "Post com ID invalid não encontrado"
  end
end
