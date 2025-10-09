class CreatePostTool < MCP::Tool
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

  def self.call(title:, description:, server_context:)
    post = Post.new(title: title, description: description)

    if post.save
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Post criado com sucesso! ID: #{post.id}, Título: #{post.title}"
      } ])
    else
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Erro ao criar post: #{post.errors.full_messages.join(', ')}"
      } ])
    end
  rescue StandardError => e
    MCP::Tool::Response.new([ {
      type: "text",
      text: "Erro ao criar post: #{e.message}"
    } ])
  end
end
