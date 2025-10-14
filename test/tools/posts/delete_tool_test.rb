require "test_helper"

class Posts::DeleteToolTest < ActiveSupport::TestCase
  test "should delete post" do
    post = Post.create!(title: "To Delete", description: "Description")

    assert_difference "Post.count", -1 do
      response = Posts::DeleteTool.call(id: post.id, server_context: {})

      json = JSON.parse(response.content.first[:text])
      assert json["success"]
      assert_equal "Post deletado com sucesso!", json["message"]
    end
  end

  test "should include post data in success response" do
    post = Post.create!(title: "Important Post", description: "Description")

    response = Posts::DeleteTool.call(id: post.id, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal post.id, json["post"]["id"]
    assert_equal "Important Post", json["post"]["title"]
  end

  test "should handle post not found" do
    assert_no_difference "Post.count" do
      response = Posts::DeleteTool.call(id: 99999, server_context: {})

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "não encontrado"
      assert_includes json["message"], "99999"
    end
  end

  test "should handle unexpected errors gracefully" do
    post = Post.create!(title: "Test Post", description: "Description")

    Post.stub :find, ->(_id) { raise StandardError.new("Unexpected error") } do
      response = Posts::DeleteTool.call(id: post.id, server_context: {})

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao deletar post"
      assert_includes json["message"], "Unexpected error"
    end
  end
end
