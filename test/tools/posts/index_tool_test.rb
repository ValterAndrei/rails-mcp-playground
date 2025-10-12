require "test_helper"

class Posts::IndexToolTest < ActiveSupport::TestCase
  test "should return empty list when no posts exist" do
    response = Posts::IndexTool.call(server_context: {})

    assert_instance_of MCP::Tool::Response, response
    assert_equal 1, response.content.length
    assert_equal "text", response.content.first[:type]
    assert_includes response.content.first[:text], "Total de posts: 0"
  end

  test "should list all posts with default parameters" do
    Post.create!(title: "Post 1", description: "Description 1")
    Post.create!(title: "Post 2", description: "Description 2")

    response = Posts::IndexTool.call(server_context: {})

    assert_instance_of MCP::Tool::Response, response
    assert_includes response.content.first[:text], "Total de posts: 2"
    assert_includes response.content.first[:text], "Post 1"
    assert_includes response.content.first[:text], "Post 2"
  end

  test "should order posts by created_at descending" do
    Post.create!(title: "Old Post", description: "Old Description", created_at: 1.day.ago)
    Post.create!(title: "New Post", description: "New Description", created_at: Time.now)

    response = Posts::IndexTool.call(server_context: {})

    text = response.content.first[:text]
    new_post_position = text.index("New Post")
    old_post_position = text.index("Old Post")

    assert new_post_position < old_post_position, "New post should appear before old post"
  end

  test "should include post details in response" do
    post = Post.create!(title: "Test Post", description: "Test Description")

    response = Posts::IndexTool.call(server_context: {})

    text = response.content.first[:text]
    assert_includes text, post.id.to_s
    assert_includes text, "Test Post"
    assert_includes text, "Test Description"
  end

  test "should filter posts by search_term in title" do
    Post.create!(title: "Ruby on Rails", description: "Framework description")
    Post.create!(title: "Python Django", description: "Another framework")

    response = Posts::IndexTool.call(search_term: "Ruby", server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 1"
    assert_includes text, "Ruby on Rails"
    assert_not_includes text, "Python Django"
  end

  test "should filter posts by search_term in description" do
    Post.create!(title: "Post 1", description: "About Ruby programming")
    Post.create!(title: "Post 2", description: "About Python programming")

    response = Posts::IndexTool.call(search_term: "Ruby", server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 1"
    assert_includes text, "Post 1"
    assert_not_includes text, "Post 2"
  end

  test "should perform case-insensitive search" do
    Post.create!(title: "Ruby Tutorial", description: "Learn Ruby")

    response = Posts::IndexTool.call(search_term: "ruby", server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 1"
    assert_includes text, "Ruby Tutorial"
  end

  test "should return all posts when search_term is nil" do
    Post.create!(title: "Post 1", description: "Description 1")
    Post.create!(title: "Post 2", description: "Description 2")

    response = Posts::IndexTool.call(search_term: nil, server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 2"
  end

  test "should limit number of results" do
    5.times { |i| Post.create!(title: "Post #{i}", description: "Description #{i}") }

    response = Posts::IndexTool.call(limit: 3, server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 3"
  end

  test "should apply offset for pagination" do
    5.times.map { |i| Post.create!(title: "Post #{i} 123", description: "Desc #{i} teste") }

    response = Posts::IndexTool.call(offset: 2, limit: 2, server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 2"
    # Deve retornar os posts do meio (considerando ordem descendente)
  end

  test "should combine search_term and limit" do
    Post.create!(title: "Ruby Post 1", description: "Ruby content")
    Post.create!(title: "Ruby Post 2", description: "Ruby content")
    Post.create!(title: "Ruby Post 3", description: "Ruby content")
    Post.create!(title: "Python Post", description: "Python content")

    response = Posts::IndexTool.call(search_term: "Ruby", limit: 2, server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 2"
    assert_includes text, "Ruby"
    assert_not_includes text, "Python"
  end

  test "should use default limit of 20" do
    25.times { |i| Post.create!(title: "Post #{i} 123", description: "Desc #{i} teste") }

    response = Posts::IndexTool.call(server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 20"
  end

  test "should use default offset of 0" do
    Post.create!(title: "First Post", description: "Description")

    response = Posts::IndexTool.call(server_context: {})

    text = response.content.first[:text]
    assert_includes text, "First Post"
  end

  test "should handle empty search_term string" do
    Post.create!(title: "Post 1", description: "Description 1")

    response = Posts::IndexTool.call(search_term: "", server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 1"
  end

  test "should handle search_term with special characters" do
    Post.create!(title: "C++ Programming", description: "Desc Learn C++")

    response = Posts::IndexTool.call(search_term: "C++", server_context: {})

    text = response.content.first[:text]
    assert_includes text, "C++ Programming"
  end

  # Testes de Ordenação

  test "should sort by created_at ascending" do
    Post.create!(title: "Old Post", description: "Desc Post Old", created_at: 2.days.ago)
    Post.create!(title: "New Post", description: "Desc Post New", created_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "created_at", sort_order: "asc", server_context: {})

    text = response.content.first[:text]
    old_post_position = text.index("Old Post")
    new_post_position = text.index("New Post")

    assert old_post_position < new_post_position, "Old post should appear before new post when sorting asc"
  end

  test "should sort by created_at descending" do
    Post.create!(title: "Old Post", description: "Desc Post Old", created_at: 2.days.ago)
    Post.create!(title: "New Post", description: "Desc Post New", created_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "created_at", sort_order: "desc", server_context: {})

    text = response.content.first[:text]
    new_post_position = text.index("New Post")
    old_post_position = text.index("Old Post")

    assert new_post_position < old_post_position, "New post should appear before old post when sorting desc"
  end

  test "should sort by updated_at ascending" do
    Post.create!(title: "First Post", description: "Desc Post 123", updated_at: 2.days.ago)
    Post.create!(title: "Second Post", description: "Desc Post 123", updated_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "updated_at", sort_order: "asc", server_context: {})

    text = response.content.first[:text]
    first_position = text.index("First")
    second_position = text.index("Second")

    assert first_position < second_position, "First updated post should appear first when sorting by updated_at asc"
  end

  test "should sort by updated_at descending" do
    Post.create!(title: "First", description: "Desc first", updated_at: 2.days.ago)
    Post.create!(title: "Second", description: "Desc second", updated_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "updated_at", sort_order: "desc", server_context: {})

    text = response.content.first[:text]
    second_position = text.index("Second")
    first_position = text.index("First")

    assert second_position < first_position, "Last updated post should appear first when sorting by updated_at desc"
  end

  test "should sort by title ascending" do
    Post.create!(title: "Zebra Post", description: "Last alphabetically")
    Post.create!(title: "Apple Post", description: "First alphabetically")
    Post.create!(title: "Monkey Post", description: "Middle alphabetically")

    response = Posts::IndexTool.call(sort_by: "title", sort_order: "asc", server_context: {})

    text = response.content.first[:text]
    apple_position = text.index("Apple Post")
    monkey_position = text.index("Monkey Post")
    zebra_position = text.index("Zebra Post")

    assert apple_position < monkey_position, "Apple should come before Monkey"
    assert monkey_position < zebra_position, "Monkey should come before Zebra"
  end

  test "should sort by title descending" do
    Post.create!(title: "Zebra Post", description: "Last alphabetically")
    Post.create!(title: "Apple Post", description: "First alphabetically")
    Post.create!(title: "Monkey Post", description: "Middle alphabetically")

    response = Posts::IndexTool.call(sort_by: "title", sort_order: "desc", server_context: {})

    text = response.content.first[:text]
    zebra_position = text.index("Zebra Post")
    monkey_position = text.index("Monkey Post")
    apple_position = text.index("Apple Post")

    assert zebra_position < monkey_position, "Zebra should come before Monkey"
    assert monkey_position < apple_position, "Monkey should come before Apple"
  end

  test "should handle case-insensitive title sorting" do
    Post.create!(title: "zebra", description: "Lowercase 132")
    Post.create!(title: "Apple", description: "Capitalized 123")
    Post.create!(title: "MONKEY", description: "Uppercase 123")

    response = Posts::IndexTool.call(sort_by: "title", sort_order: "asc", server_context: {})

    text = response.content.first[:text]
    apple_position = text.index("Apple")
    monkey_position = text.index("MONKEY")
    zebra_position = text.index("zebra")

    assert apple_position < monkey_position, "Apple should come before MONKEY"
    assert monkey_position < zebra_position, "MONKEY should come before zebra"
  end

  test "should use default sort_by when not specified" do
    Post.create!(title: "Old", description: "Desc 12345", created_at: 2.days.ago)
    Post.create!(title: "New", description: "Desc 12345", created_at: 1.day.ago)

    response = Posts::IndexTool.call(server_context: {})

    text = response.content.first[:text]
    new_position = text.index("New")
    old_position = text.index("Old")

    assert new_position < old_position, "Should default to created_at desc"
  end

  test "should use default sort_order when not specified" do
    Post.create!(title: "First", description: "Desc 12345", created_at: 2.days.ago)
    Post.create!(title: "Second", description: "Desc 12345", created_at: 1.day.ago)

    response = Posts::IndexTool.call(sort_by: "created_at", server_context: {})

    text = response.content.first[:text]
    second_position = text.index("Second")
    first_position = text.index("First")

    assert second_position < first_position, "Should default to desc order"
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

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 2"

    advanced_position = text.index("Ruby Advanced")
    basics_position = text.index("Ruby Basics")

    assert advanced_position < basics_position, "Should sort filtered results"
    assert_not_includes text, "Python"
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

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 2"
    # Deve retornar os posts 3 e 2 (considerando ordem crescente, pulando o mais antigo)
  end

  test "should handle sorting with identical timestamps" do
    timestamp = 1.day.ago
    Post.create!(title: "Post A", description: "Desc A 123", created_at: timestamp)
    Post.create!(title: "Post B", description: "Desc B 123", created_at: timestamp)
    Post.create!(title: "Post C", description: "Desc C 123", created_at: timestamp)

    response = Posts::IndexTool.call(sort_by: "created_at", sort_order: "desc", server_context: {})

    text = response.content.first[:text]
    assert_includes text, "Total de posts: 3"
    assert_includes text, "Post A"
    assert_includes text, "Post B"
    assert_includes text, "Post C"
  end

  test "should handle invalid sort_by gracefully" do
    Post.create!(title: "Test Post", description: "Description")

    # Dependendo da sua implementação, pode lançar erro ou usar valor padrão
    # Ajuste conforme o comportamento esperado
    response = Posts::IndexTool.call(sort_by: "invalid_field", server_context: {})

    # Se sua implementação valida e usa default:
    assert_instance_of MCP::Tool::Response, response
    # Ou se lança erro:
    # assert_includes response.content.first[:text], "Erro"
  end

  test "should handle invalid sort_order gracefully" do
    Post.create!(title: "Test Post", description: "Description")

    response = Posts::IndexTool.call(sort_order: "invalid", server_context: {})

    assert_instance_of MCP::Tool::Response, response
  end
end
