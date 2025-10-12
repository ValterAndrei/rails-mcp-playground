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
          description: "Novo título da postagem (opcional)"
        },
        description: {
          type: "string",
          description: "Nova descrição da postagem (opcional)"
        }
      },
      required: [ "id" ]
    )

    def self.call(id:, title: nil, description: nil, server_context:)
      post = Post.find(id)

      update_params = {}
      update_params[:title] = title if title.present?
      update_params[:description] = description if description.present?

      if update_params.empty?
        return MCP::Tool::Response.new([ {
          type: "text",
          text: "Nenhum campo fornecido para atualização"
        } ])
      end

      if post.update(update_params)
        MCP::Tool::Response.new([ {
          type: "text",
          text: "Post atualizado com sucesso! ID: #{post.id}, Título: #{post.title}"
        } ])
      else
        MCP::Tool::Response.new([ {
          type: "text",
          text: "Erro ao atualizar post: #{post.errors.full_messages.join(', ')}"
        } ])
      end
    rescue ActiveRecord::RecordNotFound
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Post com ID #{id} não encontrado"
      } ])
    rescue StandardError => e
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Erro ao atualizar post: #{e.message}"
      } ])
    end
  end
end
