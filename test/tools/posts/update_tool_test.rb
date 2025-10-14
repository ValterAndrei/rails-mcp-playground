require "test_helper"

class Posts::UpdateToolTest < ActiveSupport::TestCase
  test "should update post title" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "Updated Title",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal "Updated Title", post.reload.title
    assert_equal "Original Description", post.description
  end

  test "should update post description" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      description: "Updated Description with enough characters",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal "Original Title", post.reload.title
    assert_equal "Updated Description with enough characters", post.description
  end

  test "should update both title and description" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "New Title",
      description: "New Description with enough characters",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal "New Title", post.reload.title
    assert_equal "New Description with enough characters", post.description
  end

  test "should return updated post data" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "New Title",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal post.id, json["post"]["id"]
    assert_equal "New Title", json["post"]["title"]
    assert_equal "Original Description", json["post"]["description"]
    assert_not_nil json["post"]["created_at"]
    assert_not_nil json["post"]["updated_at"]
  end

  test "should handle empty update params" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_equal "Nenhum campo fornecido para atualização", json["message"]
  end

  test "should ignore nil values" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: nil,
      description: nil,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_equal "Nenhum campo fornecido para atualização", json["message"]
  end

  test "should ignore empty strings" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "",
      description: "",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_equal "Nenhum campo fornecido para atualização", json["message"]
  end

  test "should handle post not found" do
    response = Posts::UpdateTool.call(
      id: 99999,
      title: "New Title",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "não encontrado"
    assert_includes json["message"], "99999"
  end

  test "should not update with title too short" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "Ab",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "Erro ao atualizar post"
    assert_includes json["message"].downcase, "title"
    assert_equal "Original Title", post.reload.title
  end

  test "should not update with title too long" do
    post = Post.create!(title: "Original Title", description: "Original Description")
    long_title = "a" * 256

    response = Posts::UpdateTool.call(
      id: post.id,
      title: long_title,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "Erro ao atualizar post"
    assert_includes json["message"].downcase, "title"
    assert_equal "Original Title", post.reload.title
  end

  test "should not update with description too short" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      description: "Short",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "Erro ao atualizar post"
    assert_includes json["message"].downcase, "description"
    assert_equal "Original Description", post.reload.description
  end

  test "should not update with description too long" do
    post = Post.create!(title: "Original Title", description: "Original Description")
    long_description = "a" * 10001

    response = Posts::UpdateTool.call(
      id: post.id,
      description: long_description,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "Erro ao atualizar post"
    assert_includes json["message"].downcase, "description"
    assert_equal "Original Description", post.reload.description
  end

  test "should update with minimum valid title length" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "ABC",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal "ABC", post.reload.title
  end

  test "should update with maximum valid title length" do
    post = Post.create!(title: "Original Title", description: "Original Description")
    max_title = "a" * 255

    response = Posts::UpdateTool.call(
      id: post.id,
      title: max_title,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal 255, post.reload.title.length
  end

  test "should update with minimum valid description length" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      description: "1234567890",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal "1234567890", post.reload.description
  end

  test "should update with maximum valid description length" do
    post = Post.create!(title: "Original Title", description: "Original Description")
    max_description = "a" * 10000

    response = Posts::UpdateTool.call(
      id: post.id,
      description: max_description,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "Post atualizado com sucesso!", json["message"]
    assert_equal 10000, post.reload.description.length
  end

  test "should handle update failure with mock" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    mock_post = Minitest::Mock.new
    mock_errors = Minitest::Mock.new

    mock_errors.expect :full_messages, [ "Database connection error" ]
    mock_post.expect :update, false, [ { title: "New Title" } ]
    mock_post.expect :errors, mock_errors

    Post.stub :find, mock_post do
      response = Posts::UpdateTool.call(
        id: post.id,
        title: "New Title",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao atualizar post"
      assert_includes json["message"], "Database connection error"
    end

    mock_post.verify
    mock_errors.verify
  end

  test "should handle unexpected exceptions" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    Post.stub :find, ->(*_args) { raise StandardError.new("Unexpected error") } do
      response = Posts::UpdateTool.call(
        id: post.id,
        title: "New Title",
        server_context: {}
      )

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_includes json["message"], "Erro ao atualizar post"
      assert_includes json["message"], "Unexpected error"
    end
  end

  test "should not update with empty title when title is provided" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "   ",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_equal "Nenhum campo fornecido para atualização", json["message"]
    assert_equal "Original Title", post.reload.title
  end

  test "should keep original values when update fails" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "AB", # Muito curto
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert_not json["success"]
    assert_includes json["message"], "Erro ao atualizar post"
    assert_equal "Original Title", post.reload.title
    assert_equal "Original Description", post.reload.description
  end

  test "should return ISO8601 timestamps in updated post" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "New Title",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])

    assert json["success"]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json["post"]["created_at"])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json["post"]["updated_at"])
  end
end
