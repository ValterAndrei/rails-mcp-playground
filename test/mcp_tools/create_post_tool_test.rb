require "test_helper"

class CreatePostToolTest < ActiveSupport::TestCase
  test "should create post with valid attributes" do
    assert_difference "Post.count", 1 do
      response = CreatePostTool.call(
        title: "New Post",
        description: "New Description",
        server_context: {}
      )

      assert_includes response.content.first[:text], "Post criado com sucesso"
    end

    post = Post.last
    assert_equal "New Post", post.title
    assert_equal "New Description", post.description
  end

  test "should return post id and title on success" do
    response = CreatePostTool.call(
      title: "Test Post",
      description: "Test Description",
      server_context: {}
    )

    text = response.content.first[:text]
    post = Post.last

    assert_includes text, "ID: #{post.id}"
    assert_includes text, "Título: Test Post"
  end

  test "should not create post without title" do
    assert_no_difference "Post.count" do
      response = CreatePostTool.call(
        title: "",
        description: "Description",
        server_context: {}
      )

      assert_includes response.content.first[:text], "Erro ao criar post"
      assert_includes response.content.first[:text].downcase, "title"
    end
  end

  test "should not create post without description" do
    assert_no_difference "Post.count" do
      response = CreatePostTool.call(
        title: "Title",
        description: "",
        server_context: {}
      )

      assert_includes response.content.first[:text], "Erro ao criar post"
      assert_includes response.content.first[:text].downcase, "description"
    end
  end
end
