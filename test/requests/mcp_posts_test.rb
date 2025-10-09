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
    assert tools.any? { |t| t["name"] == "list_posts_tool" }
    assert tools.any? { |t| t["name"] == "show_post_tool" }
    assert tools.any? { |t| t["name"] == "create_post_tool" }
    assert tools.any? { |t| t["name"] == "update_post_tool" }
    assert tools.any? { |t| t["name"] == "delete_post_tool" }
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
        name: "list_posts_tool",
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
  end

  test "should handle create_post tool call" do
    request_body = {
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: "create_post_tool",
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
        name: "show_post_tool",
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
  end

  test "should handle update_post tool call" do
    post_record = Post.create!(title: "Original Title", description: "Original Description")

    request_body = {
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: {
        name: "update_post_tool",
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
        name: "delete_post_tool",
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
        name: "create_post_tool",
        arguments: {
          title: "Only Title"
          # Faltando description
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
    # O erro pode estar no result ou no error, dependendo da implementação
    assert json_response["result"] || json_response["error"]
  end

  test "should handle post not found on update" do
    request_body = {
      jsonrpc: "2.0",
      id: 8,
      method: "tools/call",
      params: {
        name: "update_post_tool",
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
    # Deve retornar uma mensagem de erro no result
    assert json_response["result"] || json_response["error"]
  end

  test "should handle post not found on delete" do
    request_body = {
      jsonrpc: "2.0",
      id: 9,
      method: "tools/call",
      params: {
        name: "delete_post_tool",
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
    # Deve retornar uma mensagem de erro no result
    assert json_response["result"] || json_response["error"]
  end
end
