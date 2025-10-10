class PostsController < ApplicationController
  def index
    @posts = Post.order(:created_at)

    render json: @posts, status: :ok
  end
end
