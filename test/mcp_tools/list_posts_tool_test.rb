require "test_helper"

class ListPostsToolTest < ActiveSupport::TestCase
  test "should return empty list when no posts exist" do
    Post.destroy_all

    response = ListPostsTool.call(server_context: {})

    assert_instance_of MCP::Tool::Response, response
    assert_equal 1, response.content.length
    assert_equal "text", response.content.first[:type]
    assert_includes response.content.first[:text], "Total de posts: 0"
  end

  test "should list all posts" do
    Post.create!(title: "Post 1", description: "Description 1")
    Post.create!(title: "Post 2", description: "Description 2")

    response = ListPostsTool.call(server_context: {})

    assert_instance_of MCP::Tool::Response, response
    assert_includes response.content.first[:text], "Total de posts: 2"
    assert_includes response.content.first[:text], "Post 1"
    assert_includes response.content.first[:text], "Post 2"
  end

  test "should order posts by created_at descending" do
    Post.create!(title: "Old Post", description: "Old Description")
    Post.create!(title: "New Post", description: "New Description")

    response = ListPostsTool.call(server_context: {})

    text = response.content.first[:text]
    new_post_position = text.index("New Post")
    old_post_position = text.index("Old Post")

    assert new_post_position < old_post_position, "New post should appear before old post"
  end

  test "should include post details in response" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = ListPostsTool.call(server_context: {})

    text = response.content.first[:text]
    assert_includes text, post.id.to_s
    assert_includes text, "Test Post"
    assert_includes text, "Test Description"
  end
end
