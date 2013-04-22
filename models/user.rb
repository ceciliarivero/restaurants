class User < Ohm::Model
  attribute :first_name
  index :first_name

  attribute :last_name
  index :last_name

  attribute :email
  attribute :password

  unique :email

  def comments
    Comment.find(:user_id => self.id)
  end

  collection :comments, :Comment
end