require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "should not save post without title and description" do
    post = Post.new
    assert_not post.save, "Saved the post without a title and description"
  end

  test "should not save post with too short title" do
    post = Post.new(title: "Hi", description: "This is a valid description with enough length")
    assert_not post.save, "Saved the post with a too short title"
  end

  test "should not save post with too long title" do
    post = Post.new(title: "a" * 256, description: "This is a valid description with enough length")
    assert_not post.save, "Saved the post with a too long title"
  end

  test "should not save post with too short description" do
    post = Post.new(title: "Valid Title", description: "Too short")
    assert_not post.save, "Saved the post with a too short description"
  end

  test "should not save post with too long description" do
    post = Post.new(title: "Valid Title", description: "a" * 10_001)
    assert_not post.save, "Saved the post with a too long description"
  end

  test "should save post with valid title and description" do
    post = Post.new(
      title: "Sample Title",
      description: "This is a valid description with enough characters."
    )
    assert post.save, "Could not save the post with valid title and description"
  end
end
