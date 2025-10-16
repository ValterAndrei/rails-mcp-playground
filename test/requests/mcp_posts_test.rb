# frozen_string_literal: true

require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_mcp_request = {
      jsonrpc: "2.0",
      id: 1,
      method: "tools/list",
      params: {}
    }.to_json
  end

  test "should handle valid MCP request" do
    post mcp_handle_path,
      params: @valid_mcp_request,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal "2.0", json_response["jsonrpc"]
    assert_not_nil json_response["result"]
  end

  test "should return available tools list" do
    request_body = {
      jsonrpc: "2.0",
      id: 1,
      method: "tools/list",
      params: {}
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)

    tools = json_response.dig("result", "tools")

    assert_kind_of Array, tools
    assert tools.any? { |t| t["name"] == "post-index-tool" }
    assert tools.any? { |t| t["name"] == "post-show-tool" }
    assert tools.any? { |t| t["name"] == "post-create-tool" }
    assert tools.any? { |t| t["name"] == "post-update-tool" }
    assert tools.any? { |t| t["name"] == "post-delete-tool" }
  end

  test "should handle list_posts tool call" do
    # Criar alguns posts para testar
    Post.create!(title: "Test 1", description: "Description 1")
    Post.create!(title: "Test 2", description: "Description 2")

    request_body = {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/call",
      params: {
        name: "post-index-tool",
        arguments: {}
      }
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 2, json_response["id"]
    assert_not_nil json_response["result"]

    # Validar estrutura do retorno da tool
    content = json_response.dig("result", "content")
    assert_kind_of Array, content

    tool_result = JSON.parse(content.first["text"])
    assert tool_result["success"]
    assert_equal 2, tool_result["total"]
    assert_equal 2, tool_result["posts"].length
  end

  test "should handle create_post tool call" do
    request_body = {
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: "post-create-tool",
        arguments: {
          title: "Test Post",
          description: "Test description"
        }
      }
    }.to_json

    assert_difference "Post.count", 1 do
      post mcp_handle_path,
        params: request_body,
        headers: { "Content-Type" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura do retorno da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert tool_result["success"]
    assert_equal "Post criado com sucesso!", tool_result["message"]
    assert_not_nil tool_result["post"]
    assert_equal "Test Post", tool_result["post"]["title"]
    assert_equal "Test description", tool_result["post"]["description"]

    # Verificar se o post foi criado corretamente
    created_post = Post.last
    assert_equal "Test Post", created_post.title
    assert_equal "Test description", created_post.description
  end

  test "should handle show_post tool call" do
    post_record = Post.create!(title: "Show Test", description: "Show Description")

    request_body = {
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: "post-show-tool",
        arguments: {
          id: post_record.id
        }
      }
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["result"]

    # Validar estrutura do retorno da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert tool_result["success"]
    assert_equal "Post encontrado com sucesso!", tool_result["message"]
    assert_equal post_record.id, tool_result["post"]["id"]
    assert_equal "Show Test", tool_result["post"]["title"]
    assert_equal "Show Description", tool_result["post"]["description"]
  end

  test "should handle update_post tool call" do
    post_record = Post.create!(title: "Original Title", description: "Original Description")

    request_body = {
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: {
        name: "post-update-tool",
        arguments: {
          id: post_record.id,
          title: "Updated Title"
        }
      }
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura do retorno da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert tool_result["success"]
    assert_equal "Post atualizado com sucesso!", tool_result["message"]
    assert_equal "Updated Title", tool_result["post"]["title"]
    assert_equal "Original Description", tool_result["post"]["description"]

    assert_equal "Updated Title", post_record.reload.title
    assert_equal "Original Description", post_record.description # Descrição não deve mudar
  end

  test "should handle delete_post tool call" do
    post_record = Post.create!(title: "To Delete", description: "Delete Description")

    request_body = {
      jsonrpc: "2.0",
      id: 5,
      method: "tools/call",
      params: {
        name: "post-delete-tool",
        arguments: {
          id: post_record.id
        }
      }
    }.to_json

    assert_difference "Post.count", -1 do
      post mcp_handle_path,
        params: request_body,
        headers: { "Content-Type" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura do retorno da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert tool_result["success"]
    assert_equal "Post deletado com sucesso!", tool_result["message"]
    assert_equal post_record.id, tool_result["post"]["id"]
    assert_equal "To Delete", tool_result["post"]["title"]
  end

  test "should handle invalid JSON" do
    post mcp_handle_path,
      params: "invalid json",
      headers: { "Content-Type" => "application/json" }

    # Dependendo de como seu MCP::Server trata erros:
    assert_response :success # ou :bad_request
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["error"]
  end

  test "should handle unknown tool call" do
    request_body = {
      jsonrpc: "2.0",
      id: 6,
      method: "tools/call",
      params: {
        name: "unknown_tool",
        arguments: {}
      }
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    json_response = JSON.parse(response.body)
    assert_not_nil json_response["error"]
  end

  test "should maintain jsonrpc protocol structure" do
    post mcp_handle_path,
      params: @valid_mcp_request,
      headers: { "Content-Type" => "application/json" }

    json_response = JSON.parse(response.body)

    assert_equal "2.0", json_response["jsonrpc"]
    assert_equal 1, json_response["id"]
    assert json_response.key?("result") || json_response.key?("error")
  end

  test "should fail to create post without required fields" do
    request_body = {
      jsonrpc: "2.0",
      id: 7,
      method: "tools/call",
      params: {
        name: "post-create-tool",
        arguments: {
          title: "Only Title",
          description: "" # Descrição faltando
        }
      }
    }.to_json

    assert_no_difference "Post.count" do
      post mcp_handle_path,
        params: request_body,
        headers: { "Content-Type" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura de erro da tool
    content = json_response.dig("error", "data")
    assert_match(
      /Invalid arguments: The property '#\/description' was not of a minimum string length of 10 in schema/i,
      content
    )
  end

  test "should handle post not found on update" do
    request_body = {
      jsonrpc: "2.0",
      id: 8,
      method: "tools/call",
      params: {
        name: "post-update-tool",
        arguments: {
          id: 99999, # ID que não existe
          title: "New Title"
        }
      }
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura de erro da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert_not tool_result["success"]
    assert_includes tool_result["message"], "não encontrado"
    assert_includes tool_result["message"], "99999"
  end

  test "should handle post not found on delete" do
    request_body = {
      jsonrpc: "2.0",
      id: 9,
      method: "tools/call",
      params: {
        name: "post-delete-tool",
        arguments: {
          id: 99999 # ID que não existe
        }
      }
    }.to_json

    assert_no_difference "Post.count" do
      post mcp_handle_path,
        params: request_body,
        headers: { "Content-Type" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura de erro da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert_not tool_result["success"]
    assert_includes tool_result["message"], "não encontrado"
    assert_includes tool_result["message"], "99999"
  end

  test "should handle post not found on show" do
    request_body = {
      jsonrpc: "2.0",
      id: 10,
      method: "tools/call",
      params: {
        name: "post-show-tool",
        arguments: {
          id: 99999
        }
      }
    }.to_json

    post mcp_handle_path,
      params: request_body,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Validar estrutura de erro da tool
    content = json_response.dig("result", "content")
    tool_result = JSON.parse(content.first["text"])

    assert_not tool_result["success"]
    assert_includes tool_result["message"], "não encontrado"
  end

  test "should return consistent JSON structure across all tools" do
    post_record = Post.create!(title: "Consistency Test", description: "Test Description")

    # Testar CreateTool
    create_request = {
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: "post-create-tool",
        arguments: { title: "New Post", description: "New Description" }
      }
    }.to_json

    post mcp_handle_path, params: create_request, headers: { "Content-Type" => "application/json" }
    create_result = JSON.parse(JSON.parse(response.body).dig("result", "content").first["text"])

    assert create_result.key?("success")
    assert create_result.key?("message")

    # Testar ShowTool
    show_request = {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/call",
      params: {
        name: "post-show-tool",
        arguments: { id: post_record.id }
      }
    }.to_json

    post mcp_handle_path, params: show_request, headers: { "Content-Type" => "application/json" }
    show_result = JSON.parse(JSON.parse(response.body).dig("result", "content").first["text"])

    assert show_result.key?("success")
    assert show_result.key?("message")

    # Testar IndexTool
    index_request = {
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: "post-index-tool",
        arguments: {}
      }
    }.to_json

    post mcp_handle_path, params: index_request, headers: { "Content-Type" => "application/json" }
    index_result = JSON.parse(JSON.parse(response.body).dig("result", "content").first["text"])

    assert index_result.key?("success")
    assert index_result.key?("message")
  end
end
