class Comment < Ohm::Model
  attribute :body

  reference :user, :User
  reference :restaurant, :Restaurant
end