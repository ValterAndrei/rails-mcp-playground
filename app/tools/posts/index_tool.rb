module Posts
  class IndexTool < MCP::Tool
    tool_name "post-index-tool"
    description "Lista todas as postagens do blog"

    input_schema(
      properties: {
        search_term: {
          type: "string",
          description: "Termo de busca para filtrar postagens (busca em título e descrição)"
        },
        limit: {
          type: "integer",
          description: "Número máximo de postagens a retornar",
          minimum: 1,
          maximum: 100,
          default: 20
        },
        offset: {
          type: "integer",
          description: "Número de postagens a pular (para paginação)",
          minimum: 0,
          default: 0
        },
        sort_by: {
          type: "string",
          description: "Campo para ordenação",
          enum: [ "created_at", "updated_at", "title" ],
          default: "created_at"
        },
        sort_order: {
          type: "string",
          description: "Direção da ordenação",
          enum: [ "asc", "desc" ],
          default: "desc"
        }
      }
    )

    output_schema(
      properties: {
        success: {
          type: "boolean",
          description: "Se a operação foi bem-sucedida"
        },
        posts: {
          type: "array",
          items: {
            type: "object",
            properties: {
              id: { type: "integer" },
              title: { type: "string" },
              description: { type: "string" },
              created_at: { type: "string", format: "date-time" },
              updated_at: { type: "string", format: "date-time" }
            }
          }
        },
        total: {
          type: "integer",
          description: "Total de posts retornados"
        },
        message: {
          type: "string",
          description: "Mensagem de retorno"
        }
      },
      required: [ "success", "posts", "total", "message" ]
    )

    def self.call(search_term: nil, limit: 20, offset: 0, sort_by: "created_at", sort_order: "desc", server_context:)
      posts = Post.where(
        "title ILIKE :search OR description ILIKE :search",
        search: "%#{search_term}%"
      ).order("#{sort_by} #{sort_order}").limit(limit).offset(offset)

      posts_data = posts.map do |post|
        {
          id: post.id,
          title: post.title,
          description: post.description,
          created_at: post.created_at.iso8601,
          updated_at: post.updated_at.iso8601
        }
      end

      result = {
        success: true,
        posts: posts_data,
        total: posts.count,
        message: "Posts listados com sucesso!"
      }

      output_schema.validate_result(result)

      MCP::Tool::Response.new([ {
        type: "text",
        text: result.to_json
      } ])
    rescue StandardError => e
      MCP::Tool::Response.new([ {
        type: "text",
        text: { success: false, posts: [], total: 0, message: "Erro ao listar posts: #{e.message}" }.to_json
      } ])
    end
  end
end
