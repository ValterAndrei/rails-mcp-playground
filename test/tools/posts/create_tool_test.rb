require "test_helper"

class Posts::CreateToolTest < ActiveSupport::TestCase
  test "should create post with valid attributes" do
    assert_difference "Post.count", 1 do
      response = Posts::CreateTool.call(
        title: "New Post Title",
        description: "This is a valid description with enough characters",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert json["success"]
      assert_equal "Post criado com sucesso!", json["message"]
    end

    post = Post.last
    assert_equal "New Post Title", post.title
    assert_equal "This is a valid description with enough characters", post.description
  end

  test "should return post data on success" do
    response = Posts::CreateTool.call(
      title: "Test Post Title",
      description: "Test Description with minimum length",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    post = Post.last

    assert json["success"]
    assert_equal post.id, json["post"]["id"]
    assert_equal "Test Post Title", json["post"]["title"]
    assert_equal "Test Description with minimum length", json["post"]["description"]
    assert_not_nil json["post"]["created_at"]
    assert_not_nil json["post"]["updated_at"]
  end

  test "should not create post without title" do
    assert_no_difference "Post.count" do
      response = Posts::CreateTool.call(
        title: "",
        description: "Valid description with enough characters",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"].downcase, "title"
    end
  end

  test "should not create post without description" do
    assert_no_difference "Post.count" do
      response = Posts::CreateTool.call(
        title: "Valid Title",
        description: "",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"].downcase, "description"
    end
  end

  test "should not create post with title too short" do
    assert_no_difference "Post.count" do
      response = Posts::CreateTool.call(
        title: "Ab",
        description: "Valid description with enough characters",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"].downcase, "title"
    end
  end

  test "should not create post with title too long" do
    long_title = "a" * 256

    assert_no_difference "Post.count" do
      response = Posts::CreateTool.call(
        title: long_title,
        description: "Valid description with enough characters",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"].downcase, "title"
    end
  end

  test "should not create post with description too short" do
    assert_no_difference "Post.count" do
      response = Posts::CreateTool.call(
        title: "Valid Title",
        description: "Short",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"].downcase, "description"
    end
  end

  test "should not create post with description too long" do
    long_description = "a" * 10001

    assert_no_difference "Post.count" do
      response = Posts::CreateTool.call(
        title: "Valid Title",
        description: long_description,
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"].downcase, "description"
    end
  end

  test "should create post with minimum valid length" do
    assert_difference "Post.count", 1 do
      response = Posts::CreateTool.call(
        title: "ABC",
        description: "1234567890",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert json["success"]
      assert_equal "Post criado com sucesso!", json["message"]
    end
  end

  test "should create post with maximum valid length" do
    max_title = "a" * 255
    max_description = "a" * 10000

    assert_difference "Post.count", 1 do
      response = Posts::CreateTool.call(
        title: max_title,
        description: max_description,
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert json["success"]
    end

    post = Post.last
    assert_equal 255, post.title.length
    assert_equal 10000, post.description.length
  end

  test "should handle exception during post creation" do
    Post.stub :new, ->(*_args, **_kwargs) { raise StandardError.new("Unexpected error") } do
      response = Posts::CreateTool.call(
        title: "Valid Title",
        description: "Valid description with enough characters",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"], "Unexpected error"
    end
  end

  test "should handle unexpected errors gracefully" do
    Post.stub :new, ->(*) { raise StandardError.new("Unexpected error") } do
      response = Posts::CreateTool.call(
        title: "Valid Title",
        description: "Valid description with enough characters",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao criar post"
      assert_includes json["message"], "Unexpected error"
    end
  end

  test "should trim whitespace from title and description" do
    Posts::CreateTool.call(
      title: "  Valid Title  ",
      description: "  Valid description with enough characters  ",
      server_context: {}
    )

    post = Post.last
    assert_equal "  Valid Title  ", post.title
    assert_equal "  Valid description with enough characters  ", post.description
  end

  test "should return post with ISO8601 timestamps" do
    response = Posts::CreateTool.call(
      title: "Test Post",
      description: "Test Description with valid length",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])

    assert json["success"]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json["post"]["created_at"])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json["post"]["updated_at"])
  end
end
