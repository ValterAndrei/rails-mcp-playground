module Posts
  class UpdateTool < MCP::Tool
    tool_name "post-update-tool"
    description "Atualiza uma postagem existente"

    input_schema(
      properties: {
        id: {
          type: "integer",
          description: "ID da postagem a ser atualizada"
        },
        title: {
          type: "string",
          description: "Novo título da postagem (opcional)",
          minLength: 3,
          maxLength: 255
        },
        description: {
          type: "string",
          description: "Nova descrição da postagem (opcional)",
          minLength: 10,
          maxLength: 10000
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

    def self.call(id:, title: nil, description: nil, server_context:)
      post = Post.find(id)

      update_params = {}
      update_params[:title] = title if title.present?
      update_params[:description] = description if description.present?

      if update_params.empty?
        return MCP::Tool::Response.new([ {
          type: "text",
          text: { success: false, message: "Nenhum campo fornecido para atualização" }.to_json
        } ])
      end

      if post.update(update_params)
        result = {
          success: true,
          post: {
            id: post.id,
            title: post.title,
            description: post.description,
            created_at: post.created_at.iso8601,
            updated_at: post.updated_at.iso8601
          },
          message: "Post atualizado com sucesso!"
        }

        output_schema.validate_result(result)

        MCP::Tool::Response.new([ {
          type: "text",
          text: result.to_json
        } ])
      else
        MCP::Tool::Response.new([ {
          type: "text",
          text: { success: false, message: "Erro ao atualizar post: #{post.errors.full_messages.join(', ')}" }.to_json
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
        text: { success: false, message: "Erro ao atualizar post: #{e.message}" }.to_json
      } ])
    end
  end
end
