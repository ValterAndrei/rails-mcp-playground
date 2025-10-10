# README

- Instalar dependências no seu VScode
  - [Devcontainer](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

- Iniciar o servidor Rails:
```bash
bin/rails server -b 0.0.0.0 -p 3000
```

- Iniciar o servidor Rails com rdbg (para depuração):
```bash
bundle exec rdbg --open --port 12345 --host 0.0.0.0 --nonstop --command -- \
  bin/rails server -b 0.0.0.0 -p 3000
```

- Executar testes:
```bash
bin/rails test
```

---

### 🧩 Conceitos básicos MCP

1️⃣ Server (Servidor MCP)

👉 É quem **oferece ferramentas** (_tools_) que uma IA pode usar.

- Ele **exponde endpoints JSON-RPC** via `/mcp`.
- Ele **descreve** suas ferramentas no método `tools/list`.
- Ele **executa** uma ferramenta quando o cliente pede via `tools/call`.

2️⃣ Client (Cliente MCP)

👉 É quem **consome** (_tools_) essas ferramentas.

- Pode ser uma **IA** (como ChatGPT, Claude, Llama, etc).
- Ou um **agente** intermediário (ex: script em Python ou Ruby que conecta o LLM ao teu MCP Server).
- O cliente faz:
  - `tools/list` → pergunta “que ferramentas você oferece?”
  - `tools/call` → executa uma ferramenta com certos parâmetros

🔶 Diagrama visual
```
                   ┌────────────────────────┐
                   │        Usuário         │
                   │  "Crie um post..."     │
                   └──────────┬─────────────┘
                              │
                              ▼
                  ┌────────────────────────┐
                  │      LLM (Cliente)     │
                  │  Ex: ChatGPT / Claude  │
                  │   ou LLM local (Ollama)│
                  └──────────┬─────────────┘
                             │
                             │ JSON-RPC (tools/list, tools/call)
                             ▼
           ┌──────────────────────────────────────────┐
           │         🚀 Rails App (MCP Server)        │
           │     Expondo endpoint: /mcp               │
           │------------------------------------------│
           │ Tools:                                   │
           │  - create_post_tool                      │
           │  - list_posts_tool                       │
           │  - update_post_tool                      │
           │  - delete_post_tool                      │
           │------------------------------------------│
           │ Usa models e lógica do Rails:            │
           │  Post.create, Post.all, etc.             │
           └──────────────────────────────────────────┘
                             │
                             ▼
               ┌───────────────────────────┐
               │    Banco de Dados (PG)    │
               │  posts(id, title, desc)   │
               └───────────────────────────┘
```
