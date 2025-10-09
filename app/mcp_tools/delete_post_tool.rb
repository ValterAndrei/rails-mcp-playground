class DeletePostTool < MCP::Tool
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

  def self.call(id:, server_context:)
    post = Post.find(id)
    title = post.title

    if post.destroy
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Post '#{title}' (ID: #{id}) deletado com sucesso!"
      } ])
    else
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Erro ao deletar post: #{post.errors.full_messages.join(', ')}"
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
      text: "Erro ao deletar post: #{e.message}"
    } ])
  end
end
