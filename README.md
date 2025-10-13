# README

## MCP with Ruby on Rails

This is an example project that demonstrates the implementation of the MCP (Model-Context-Protocol) protocol using Ruby on Rails. MCP allows language models (LLMs) to interact with external tools through a JSON-RPC interface.

---

### 🚀 How to run the project

- Install dependencies in your VSCode
  - [Devcontainer](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

- Start the Rails server:
```bash
bin/rails server -b 0.0.0.0 -p 3000
```

- Start the Rails server with rdbg (for debugging):
```bash
bundle exec rdbg --open --port 12345 --host 0.0.0.0 --nonstop --command -- \
  bin/rails server -b 0.0.0.0 -p 3000
```

- Run tests:
```bash
bin/rails test
```

---

### 🧩 MCP Basic Concepts

**1️⃣ Server (MCP Server)**

👉 It's the one that **provides tools** (_tools_) that an AI can use.
- It **exposes JSON-RPC endpoints** via `/mcp`.
- It **describes** its tools in the `tools/list` method.
- It **executes** a tool when the client requests it via `tools/call`.

**2️⃣ Client (MCP Client)**

👉 It's the one that **consumes** those tools (_tools_).
- It can be an **AI** (like ChatGPT, Claude, Llama, etc).
- Or an **intermediary agent** (e.g., a Python or Ruby script that connects the LLM to your MCP Server).
- The client performs:
  - `tools/list` → asks "what tools do you offer?"
  - `tools/call` → executes a tool with certain parameters

**🔶 Visual Diagram**
```
                   ┌────────────────────────┐
                   │         User           │
                   │  "Create a post..."    │
                   └──────────┬─────────────┘
                              │
                              ▼
                  ┌────────────────────────┐
                  │    LLM (Client)        │
                  │  Ex: ChatGPT / Claude  │
                  │  or local LLM (Ollama) │
                  └──────────┬─────────────┘
                             │
                             │ JSON-RPC (tools/list, tools/call)
                             ▼
           ┌──────────────────────────────────────────┐
           │         🚀 Rails App (MCP Server)        │
           │     Exposing endpoint: /mcp              │
           │------------------------------------------│
           │ Tools:                                   │
           │  - post-create-tool                      │
           │  - post-delete-tool                      │
           │  - post-index-tool                       │
           │  - post-show-tool                        │
           │  - post-update-tool                      │
           │------------------------------------------│
           │ Uses Rails models and logic:             │
           │  Post.create, Post.all, etc.             │
           └──────────────────────────────────────────┘
                             │
                             ▼
               ┌──────────────────────────────────┐
               │    Database (PG)                 │
               │  posts(id, title, description)   │
               └──────────────────────────────────┘
```
