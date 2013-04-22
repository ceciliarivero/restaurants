class Restaurant < Ohm::Model
  attribute :name
  index :name

  attribute :cuisine
  index :cuisine

  attribute :rating

  def comments
    Comment.find(:restaurant_id => self.id)
  end

  collection :comments, :Comment
end