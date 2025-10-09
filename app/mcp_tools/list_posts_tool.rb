class ListPostsTool < MCP::Tool
  description "Lista todas as postagens do blog"

  input_schema(
    properties: {},
    required: []
  )

  def self.call(server_context:)
    posts = Post.all.order(created_at: :desc)

    posts_data = posts.map do |post|
      {
        id: post.id,
        title: post.title,
        description: post.description,
        created_at: post.created_at.iso8601,
        updated_at: post.updated_at.iso8601
      }
    end

    MCP::Tool::Response.new([ {
      type: "text",
      text: "Total de posts: #{posts.count}\n\n#{posts_data.to_json}"
    } ])
  rescue StandardError => e
    MCP::Tool::Response.new([ {
      type: "text",
      text: "Erro ao listar posts: #{e.message}"
    } ])
  end
end
