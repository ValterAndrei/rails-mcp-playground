class Post < ApplicationRecord
  validates :title,       presence: true, length: { minimum: 3, maximum: 255 }
  validates :description, presence: true, length: { minimum: 10, maximum: 10000 }
end
