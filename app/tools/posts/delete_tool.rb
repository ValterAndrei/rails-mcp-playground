module Posts
  class DeleteTool < MCP::Tool
    tool_name "post-delete-tool"
    description "Deleta uma postagem do blog"

    input_schema(
      properties: {
        id: {
          type: "integer",
          description: "ID da postagem a ser deletada"
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
            title: { type: "string" }
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
      post_data = {
        id: post.id,
        title: post.title
      }

      if post.destroy
        result = {
          success: true,
          post: post_data,
          message: "Post deletado com sucesso!"
        }

        output_schema.validate_result(result)

        MCP::Tool::Response.new([ {
          type: "text",
          text: result.to_json
        } ])
      else
        MCP::Tool::Response.new([ {
          type: "text",
          text: { success: false, message: "Erro ao deletar post: #{post.errors.full_messages.join(', ')}" }.to_json
        } ])
      end
    rescue ActiveRecord::RecordNotFound
      MCP::Tool::Response.new([ {
        type: "text",
        text: { success: false, message: "Post com ID #{id} não encontrado" }.to_json
      } ])
    rescue StandardError => e
      MCP::Tool::Response.new([ {
        type: "text",
        text: { success: false, message: "Erro ao deletar post: #{e.message}" }.to_json
      } ])
    end
  end
end
