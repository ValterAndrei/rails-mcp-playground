module Posts
  class CreateTool < MCP::Tool
    tool_name "post-create-tool"
    description "Cria uma nova postagem no blog"

    input_schema(
      properties: {
        title: {
          type: "string",
          description: "Título da postagem (obrigatório)"
        },
        description: {
          type: "string",
          description: "Descrição/conteúdo da postagem (obrigatório)"
        }
      },
      required: [ "title", "description" ]
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

    def self.call(title:, description:, server_context:)
      post = Post.new(title: title, description: description)

      if post.save
        result = {
          success: true,
          post: {
            id: post.id,
            title: post.title,
            description: post.description,
            created_at: post.created_at.iso8601,
            updated_at: post.updated_at.iso8601
          },
          message: "Post criado com sucesso!"
        }

        output_schema.validate_result(result)

        MCP::Tool::Response.new([ {
          type: "text",
          text: result.to_json
        } ])
      else
        MCP::Tool::Response.new([ {
          type: "text",
          text: { success: false, message: "Erro ao criar post: #{post.errors.full_messages.join(', ')}" }.to_json
        } ])
      end
    rescue StandardError => e
      MCP::Tool::Response.new([ {
        type: "text",
        text: { success: false, message: "Erro ao criar post: #{e.message}" }.to_json
      } ])
    end
  end
end
