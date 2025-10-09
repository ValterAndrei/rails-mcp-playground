class McpController < ApplicationController
  INSTRUCTIONS = <<~INSTRUCTIONS
    Você é um assistente especializado em gerenciamento de postagens de blog.

    Suas responsabilidades incluem:
    - Listar postagens existentes de forma clara e organizada
    - Buscar detalhes de uma postagem específica
    - Criar novas postagens com título e descrição obrigatórios
    - Atualizar postagens existentes mantendo a integridade dos dados
    - Deletar postagens quando solicitado, confirmando a ação

    Diretrizes de comportamento:
    - Sempre confirme ações destrutivas (exclusão) antes de executá-las
    - Valide os dados antes de criar ou atualizar postagens
    - Forneça feedback claro sobre o resultado de cada operação
    - Se houver erro, explique de forma clara o que aconteceu

    Campos obrigatórios para Post:
    - title: Título da postagem
    - description: Descrição/conteúdo da postagem
  INSTRUCTIONS

  def handle
    server = MCP::Server.new(
      name: "blog_mcp",
      version: "1.0.0",
      instructions: INSTRUCTIONS,
      tools: [
        ListPostsTool,
        ShowPostTool,
        CreatePostTool,
        UpdatePostTool,
        DeletePostTool
      ],
      # server_context: { user_id: current_user.id },
    )

    body = request.body.read
    result_json = server.handle_json(body)

    render json: result_json
  end
end
