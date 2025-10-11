require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should get index and return posts ordered by created_at" do
    # Arrange: Cria posts com datas diferentes
    post1 = Post.create!(title: "Primeiro Post", description: "Primeiro", created_at: 2.days.ago)
    post2 = Post.create!(title: "Segundo Post", description: "Segundo", created_at: 1.day.ago)
    post3 = Post.create!(title: "Terceiro Post", description: "Terceiro", created_at: Time.current)

    # Act: Faz a requisição
    get posts_path

    # Assert: Verifica a resposta
    assert_response :ok
    assert_equal "application/json; charset=utf-8", @response.content_type

    # Parse do JSON retornado
    json_response = JSON.parse(@response.body)

    # Verifica se retornou 3 posts
    assert_equal 3, json_response.length

    # Verifica a ordem (do mais antigo para o mais recente)
    assert_equal post1.id, json_response[0]["id"]
    assert_equal post2.id, json_response[1]["id"]
    assert_equal post3.id, json_response[2]["id"]
  end

  test "should return empty array when no posts exist" do
    # Arrange: Garante que não existem posts
    Post.destroy_all

    # Act
    get posts_path

    # Assert
    assert_response :ok
    json_response = JSON.parse(@response.body)
    assert_equal [], json_response
  end

  test "should return all posts" do
    # Arrange: Cria múltiplos posts
    5.times { |i| Post.create!(title: "Post #{i}", description: "Description #{i}") }

    # Act
    get posts_path

    # Assert
    assert_response :ok
    json_response = JSON.parse(@response.body)
    assert_equal 5, json_response.length
  end
end
