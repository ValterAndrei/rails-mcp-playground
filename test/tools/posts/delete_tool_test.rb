require "test_helper"

class Posts::DeleteToolTest < ActiveSupport::TestCase
  test "should delete post" do
    post = Post.create!(title: "To Delete", description: "Description")

    assert_difference "Post.count", -1 do
      response = Posts::DeleteTool.call(id: post.id, server_context: {})

      assert_includes response.content.first[:text], "deletado com sucesso"
    end
  end

  test "should include post title in success message" do
    post = Post.create!(title: "Important Post", description: "Description")

    response = Posts::DeleteTool.call(id: post.id, server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Important Post"
    assert_includes text, "ID: #{post.id}"
  end

  test "should handle post not found" do
    assert_no_difference "Post.count" do
      response = Posts::DeleteTool.call(id: 99999, server_context: {})

      assert_includes response.content.first[:text], "não encontrado"
    end
  end
end
