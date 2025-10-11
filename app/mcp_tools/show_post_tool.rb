class ShowPostTool < MCP::Tool
  description "Exibe detalhes de uma postagem específica"

  input_schema(
    properties: {
      id: {
        type: "integer",
        description: "ID da postagem"
      }
    },
    required: [ "id" ]
  )

  def self.call(id:, server_context:)
    post = Post.find(id)

    post_data = {
      id: post.id,
      title: post.title,
      description: post.description,
      created_at: post.created_at.iso8601,
      updated_at: post.updated_at.iso8601
    }

    MCP::Tool::Response.new([ {
      type: "text",
      text: "Post encontrado:\n#{post_data.to_json}"
    } ])
  rescue ActiveRecord::RecordNotFound
    MCP::Tool::Response.new([ {
      type: "text",
      text: "Post com ID #{id} não encontrado"
    } ])
  rescue StandardError => e
    MCP::Tool::Response.new([ {
      type: "text",
      text: "Erro ao buscar post: #{e.message}"
    } ])
  end
end
