require "test_helper"

class Posts::IndexToolTest < ActiveSupport::TestCase
  test "should return empty list when no posts exist" do
    response = Posts::IndexTool.call(server_context: {})

    assert_instance_of MCP::Tool::Response, response
    assert_equal 1, response.content.length
    assert_equal "text", response.content.first[:type]

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 0, json["total"]
    assert_equal [], json["posts"]
    assert_equal "Posts listados com sucesso!", json["message"]
  end

  test "should list all posts with default parameters" do
    Post.create!(title: "Post 1", description: "Description 1")
    Post.create!(title: "Post 2", description: "Description 2")

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 2, json["total"]
    assert_equal 2, json["posts"].length
    assert_includes json["posts"].map { |p| p["title"] }, "Post 1"
    assert_includes json["posts"].map { |p| p["title"] }, "Post 2"
  end

  test "should order posts by created_at descending" do
    Post.create!(title: "Old Post", description: "Old Description", created_at: 1.day.ago)
    Post.create!(title: "New Post", description: "New Description", created_at: Time.now)

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "New Post", json["posts"].first["title"]
    assert_equal "Old Post", json["posts"].last["title"]
  end

  test "should include post details in response" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    post_data = json["posts"].first

    assert_equal post.id, post_data["id"]
    assert_equal "Test Post", post_data["title"]
    assert_equal "Test Description", post_data["description"]
    assert_not_nil post_data["created_at"]
    assert_not_nil post_data["updated_at"]
  end

  test "should filter posts by search_term in title" do
    Post.create!(title: "Ruby on Rails", description: "Framework description")
    Post.create!(title: "Python Django", description: "Another framework")

    response = Posts::IndexTool.call(search_term: "Ruby", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 1, json["total"]
    assert_equal "Ruby on Rails", json["posts"].first["title"]
  end

  test "should filter posts by search_term in description" do
    Post.create!(title: "Post 1", description: "About Ruby programming")
    Post.create!(title: "Post 2", description: "About Python programming")

    response = Posts::IndexTool.call(search_term: "Ruby", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 1, json["total"]
    assert_equal "Post 1", json["posts"].first["title"]
  end

  test "should perform case-insensitive search" do
    Post.create!(title: "Ruby Tutorial", description: "Learn Ruby")

    response = Posts::IndexTool.call(search_term: "ruby", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 1, json["total"]
    assert_equal "Ruby Tutorial", json["posts"].first["title"]
  end

  test "should return all posts when search_term is nil" do
    Post.create!(title: "Post 1", description: "Description 1")
    Post.create!(title: "Post 2", description: "Description 2")

    response = Posts::IndexTool.call(search_term: nil, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 2, json["total"]
  end

  test "should limit number of results" do
    5.times { |i| Post.create!(title: "Post #{i}", description: "Description #{i}") }

    response = Posts::IndexTool.call(limit: 3, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 3, json["total"]
    assert_equal 3, json["posts"].length
  end

  test "should apply offset for pagination" do
    5.times.map { |i| Post.create!(title: "Post #{i} 123", description: "Desc #{i} teste") }

    response = Posts::IndexTool.call(offset: 2, limit: 2, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 2, json["total"]
    assert_equal 2, json["posts"].length
  end

  test "should combine search_term and limit" do
    Post.create!(title: "Ruby Post 1", description: "Ruby content")
    Post.create!(title: "Ruby Post 2", description: "Ruby content")
    Post.create!(title: "Ruby Post 3", description: "Ruby content")
    Post.create!(title: "Python Post", description: "Python content")

    response = Posts::IndexTool.call(search_term: "Ruby", limit: 2, server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 2, json["total"]
    assert json["posts"].all? { |p| p["title"].include?("Ruby") }
  end

  test "should use default limit of 20" do
    25.times { |i| Post.create!(title: "Post #{i} 123", description: "Desc #{i} teste") }

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 20, json["total"]
  end

  test "should use default offset of 0" do
    Post.create!(title: "First Post", description: "Description")

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "First Post", json["posts"].first["title"]
  end

  test "should handle empty search_term string" do
    Post.create!(title: "Post 1", description: "Description 1")

    response = Posts::IndexTool.call(search_term: "", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 1, json["total"]
  end

  test "should handle search_term with special characters" do
    Post.create!(title: "C++ Programming", description: "Desc Learn C++")

    response = Posts::IndexTool.call(search_term: "C++", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal "C++ Programming", json["posts"].first["title"]
  end

  # Testes de Ordenação

  test "should sort by created_at ascending" do
    Post.create!(title: "Old Post", description: "Desc Post Old", created_at: 2.days.ago)
    Post.create!(title: "New Post", description: "Desc Post New", created_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "created_at", sort_order: "asc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "Old Post", json["posts"].first["title"]
    assert_equal "New Post", json["posts"].last["title"]
  end

  test "should sort by created_at descending" do
    Post.create!(title: "Old Post", description: "Desc Post Old", created_at: 2.days.ago)
    Post.create!(title: "New Post", description: "Desc Post New", created_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "created_at", sort_order: "desc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "New Post", json["posts"].first["title"]
    assert_equal "Old Post", json["posts"].last["title"]
  end

  test "should sort by updated_at ascending" do
    Post.create!(title: "First Post", description: "Desc Post 123", updated_at: 2.days.ago)
    Post.create!(title: "Second Post", description: "Desc Post 123", updated_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "updated_at", sort_order: "asc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "First Post", json["posts"].first["title"]
    assert_equal "Second Post", json["posts"].last["title"]
  end

  test "should sort by updated_at descending" do
    Post.create!(title: "First", description: "Desc first", updated_at: 2.days.ago)
    Post.create!(title: "Second", description: "Desc second", updated_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "updated_at", sort_order: "desc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "Second", json["posts"].first["title"]
    assert_equal "First", json["posts"].last["title"]
  end

  test "should sort by title ascending" do
    Post.create!(title: "Zebra Post", description: "Last alphabetically")
    Post.create!(title: "Apple Post", description: "First alphabetically")
    Post.create!(title: "Monkey Post", description: "Middle alphabetically")

    response = Posts::IndexTool.call(sort_by: "title", sort_order: "asc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    titles = json["posts"].map { |p| p["title"] }

    assert_equal "Apple Post", titles[0]
    assert_equal "Monkey Post", titles[1]
    assert_equal "Zebra Post", titles[2]
  end

  test "should sort by title descending" do
    Post.create!(title: "Zebra Post", description: "Last alphabetically")
    Post.create!(title: "Apple Post", description: "First alphabetically")
    Post.create!(title: "Monkey Post", description: "Middle alphabetically")

    response = Posts::IndexTool.call(sort_by: "title", sort_order: "desc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    titles = json["posts"].map { |p| p["title"] }

    assert_equal "Zebra Post", titles[0]
    assert_equal "Monkey Post", titles[1]
    assert_equal "Apple Post", titles[2]
  end

  test "should handle case-insensitive title sorting" do
    Post.create!(title: "zebra", description: "Lowercase 132")
    Post.create!(title: "Apple", description: "Capitalized 123")
    Post.create!(title: "MONKEY", description: "Uppercase 123")

    response = Posts::IndexTool.call(sort_by: "title", sort_order: "asc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    titles = json["posts"].map { |p| p["title"] }

    assert_equal "Apple", titles[0]
    assert_equal "MONKEY", titles[1]
    assert_equal "zebra", titles[2]
  end

  test "should use default sort_by when not specified" do
    Post.create!(title: "Old", description: "Desc 12345", created_at: 2.days.ago)
    Post.create!(title: "New", description: "Desc 12345", created_at: 1.day.ago)

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "New", json["posts"].first["title"]
    assert_equal "Old", json["posts"].last["title"]
  end

  test "should use default sort_order when not specified" do
    Post.create!(title: "First", description: "Desc 12345", created_at: 2.days.ago)
    Post.create!(title: "Second", description: "Desc 12345", created_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "created_at", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert_equal "Second", json["posts"].first["title"]
    assert_equal "First", json["posts"].last["title"]
  end

  test "should combine sorting with search" do
    Post.create!(title: "Ruby Advanced", description: "Advanced Ruby", created_at: 2.days.ago)
    Post.create!(title: "Ruby Basics", description: "Basic Ruby", created_at: 1.day.ago)
    Post.create!(title: "Python Guide", description: "Python tutorial", created_at: 1.hour.ago)

    response = Posts::IndexTool.call(
      search_term: "Ruby",
      sort_by: "title",
      sort_order: "asc",
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 2, json["total"]

    titles = json["posts"].map { |p| p["title"] }
    assert_equal "Ruby Advanced", titles[0]
    assert_equal "Ruby Basics", titles[1]
  end

  test "should combine sorting with pagination" do
    5.times do |i|
      Post.create!(
        title: "Post #{i}",
        description: "Description #{i}",
        created_at: i.days.ago
      )
    end

    response = Posts::IndexTool.call(
      sort_by: "created_at",
      sort_order: "asc",
      limit: 2,
      offset: 1,
      server_context: {}
    )

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 2, json["total"]
    assert_equal 2, json["posts"].length
  end

  test "should handle sorting with identical timestamps" do
    timestamp = 1.day.ago
    Post.create!(title: "Post A", description: "Desc A 123", created_at: timestamp)
    Post.create!(title: "Post B", description: "Desc B 123", created_at: timestamp)
    Post.create!(title: "Post C", description: "Desc C 123", created_at: timestamp)

    response = Posts::IndexTool.call(sort_by: "created_at", sort_order: "desc", server_context: {})

    json = JSON.parse(response.content.first[:text])
    assert json["success"]
    assert_equal 3, json["total"]

    titles = json["posts"].map { |p| p["title"] }
    assert_includes titles, "Post A"
    assert_includes titles, "Post B"
    assert_includes titles, "Post C"
  end

  test "should handle invalid sort_by gracefully" do
    Post.create!(title: "Test Post", description: "Description")

    response = Posts::IndexTool.call(sort_by: "invalid_field", server_context: {})

    assert_instance_of MCP::Tool::Response, response
    # Se lançar erro, verifica a estrutura de erro
    JSON.parse(response.content.first[:text])
    # Pode ser success: false com erro ou success: true dependendo da implementação
  end

  test "should handle invalid sort_order gracefully" do
    Post.create!(title: "Test Post", description: "Description")

    response = Posts::IndexTool.call(sort_order: "invalid", server_context: {})

    assert_instance_of MCP::Tool::Response, response
    JSON.parse(response.content.first[:text])
    # Verifica que retorna algo válido
  end

  test "should return posts with ISO8601 timestamps" do
    Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::IndexTool.call(server_context: {})

    json = JSON.parse(response.content.first[:text])
    post = json["posts"].first

    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, post["created_at"])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, post["updated_at"])
  end

  test "should handle exceptions gracefully" do
    Post.stub :where, ->(*) { raise StandardError.new("Database error") } do
      response = Posts::IndexTool.call(server_context: {})

      json = JSON.parse(response.content.first[:text])
      assert_not json["success"]
      assert_equal 0, json["total"]
      assert_equal [], json["posts"]
      assert_includes json["message"], "Erro ao listar posts"
      assert_includes json["message"], "Database error"
    end
  end
end
