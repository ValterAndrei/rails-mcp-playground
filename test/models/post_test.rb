require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "should not save post without title and description" do
    post = Post.new
    assert_not post.save, "Saved the post without a title and description"
  end

  test "should save post with title and description" do
    post = Post.new(title: "Sample Title", description: "Sample Description")
    assert post.save, "Could not save the post with a title and description"
  end
end
