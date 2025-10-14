module Posts
  class ShowTool < MCP::Tool
    tool_name "post-show-tool"
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

    output_schema(
      properties: {
        success: {
          type: "boolean",
          description: "Se a operação foi bem-sucedida"
        },
        post: {
          type: "object",
          properties: {
            id: { type: "integer" },
            title: { type: "string" },
            description: { type: "string" },
            created_at: { type: "string", format: "date-time" },
            updated_at: { type: "string", format: "date-time" }
          }
        },
        message: {
          type: "string",
          description: "Mensagem de retorno"
        }
      },
      required: [ "success", "message" ]
    )

    def self.call(id:, server_context:)
      post = Post.find(id)

      result = {
        success: true,
        post: {
          id: post.id,
          title: post.title,
          description: post.description,
          created_at: post.created_at.iso8601,
          updated_at: post.updated_at.iso8601
        },
        message: "Post encontrado com sucesso!"
      }

      output_schema.validate_result(result)

      MCP::Tool::Response.new([ {
        type: "text",
        text: result.to_json
      } ])
    rescue ActiveRecord::RecordNotFound
      MCP::Tool::Response.new([ {
        type: "text",
        text: { success: false, message: "Post com ID #{id} não encontrado" }.to_json
      } ])
    rescue StandardError => e
      MCP::Tool::Response.new([ {
        type: "text",
        text: { success: false, message: "Erro ao buscar post: #{e.message}" }.to_json
      } ])
    end
  end
end
