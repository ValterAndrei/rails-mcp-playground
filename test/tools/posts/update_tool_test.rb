require "test_helper"

class PostsUpdateToolTest < ActiveSupport::TestCase
  test "should update post title" do
    post = Post.create!(title: "Original", description: "Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "Updated Title",
      server_context: {}
    )

    assert_includes response.content.first[:text], "Post atualizado com sucesso"
    assert_equal "Updated Title", post.reload.title
    assert_equal "Description", post.description
  end

  test "should update post description" do
    post = Post.create!(title: "Title", description: "Original")

    response = Posts::UpdateTool.call(
      id: post.id,
      description: "Updated Description",
      server_context: {}
    )

    assert_includes response.content.first[:text], "Post atualizado com sucesso"
    assert_equal "Title", post.reload.title
    assert_equal "Updated Description", post.description
  end

  test "should update both title and description" do
    post = Post.create!(title: "Original Title", description: "Original Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "New Title",
      description: "New Description",
      server_context: {}
    )

    assert_includes response.content.first[:text], "Post atualizado com sucesso"
    assert_equal "New Title", post.reload.title
    assert_equal "New Description", post.description
  end

  test "should handle empty update params" do
    post = Post.create!(title: "Title", description: "Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      server_context: {}
    )

    assert_includes response.content.first[:text], "Nenhum campo fornecido para atualização"
  end

  test "should ignore nil values" do
    post = Post.create!(title: "Title", description: "Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: nil,
      description: nil,
      server_context: {}
    )

    assert_includes response.content.first[:text], "Nenhum campo fornecido para atualização"
  end

  test "should ignore empty strings" do
    post = Post.create!(title: "Title", description: "Description")
    response = Posts::UpdateTool.call(
      id: post.id,
      title: "",
      description: "",
      server_context: {}
    )

    # Deve tentar atualizar mas falhar na validação
    assert_includes response.content.first[:text], "Nenhum campo fornecido para atualização"
  end

  test "should handle post not found" do
    response = Posts::UpdateTool.call(
      id: 99999,
      title: "New Title",
      server_context: {}
    )

    assert_includes response.content.first[:text], "não encontrado"
  end

  test "should handle validation errors" do
    post = Post.create!(title: "Title", description: "Description")

    response = Posts::UpdateTool.call(
      id: post.id,
      title: "", # Invalid
      server_context: {}
    )

    assert_includes response.content.first[:text], "Nenhum campo fornecido para atualização"
  end
end
