# encoding: utf-8
ENV["REDIS_URL"] = "redis://localhost:6379/1"

require "cuba"
require "mote"
require "rack/protection"
require "digest/sha1"
require "ohm"

Cuba.plugin Mote::Helpers

Cuba.use Rack::Static,
  urls: %w[/js /css /img],
  root: "./public"

Cuba.use Rack::MethodOverride
Cuba.use Rack::Session::Cookie,
  key: "restaurants",
  secret: "5768a9b4ed0bd9d9cee9db8a0e50b730a28c4567"

Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Dir["./models/**/*.rb"].each  { |rb| require rb }
Dir["./routes/**/*.rb"].each  { |rb| require rb }

class EditAdmin < Scrivener
  attr_accessor :email
  attr_accessor :password

  def validate
    assert_email :email
    assert_present :password
  end
end

class EditUser < Scrivener
  attr_accessor :first_name
  attr_accessor :last_name
  attr_accessor :email
  attr_accessor :password

  def validate
    assert_present :first_name
    assert_present :last_name
    assert_email :email
    assert_present :password
  end
end

class EditRestaurant < Scrivener
  attr_accessor :name
  attr_accessor :cuisine
  attr_accessor :rating

  def validate
    assert_present :name
    assert_present :cuisine
    assert_numeric :rating
  end
end

class EditComment < Scrivener
  attr_accessor :body

  def validate
    assert_present :body
  end
end

class SearchUsers < Scrivener
  attr_accessor :email

  def validate
    assert_email :email
  end
end

Cuba.define do
  on root do
    res.write mote("views/layout.mote",
      title: "Restaurants",
      user_id: session[:user],
      admin_id: session[:admin],
      content: mote("views/home.mote"))
  end

  on "admin" do
    run Admins
  end

  on default do
    run Guests
  end
end
