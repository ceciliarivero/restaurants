class Admin < Ohm::Model
  attribute :email
  attribute :password

  unique :email
end