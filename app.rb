# encoding: utf-8

ENV["REDIS_URL"] = "redis://redistogo:2de8f67b9f05b8d22eeb8424dae08f3d@viperfish.redistogo.com:9109/"

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
  secret: "your_secret_here"

Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Dir["./models/**/*.rb"].each  { |rb| require rb }
Dir["./routes/**/*.rb"].each  { |rb| require rb }

class EditAdmin < Scrivener
  attr_accessor :email, :password

  def validate
    assert_email :email
    assert_present :password
  end
end

class EditUser < Scrivener
  attr_accessor :first_name, :last_name, :email, :password

  def validate
    assert_present :first_name
    assert_present :last_name
    assert_email :email
    assert_present :password
  end
end

class EditRestaurant < Scrivener
  attr_accessor :name, :cuisine, :rating

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

class FindUsers < Scrivener
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
      content: mote("views/home.mote",
        link_by_name: "/restaurants_by_name_desc",
        link_by_cuisine: "/restaurants_by_cuisine_desc",
        link_by_rating: "/restaurants_by_rating_desc",
        restaurants: Restaurant.all.sort_by(:name, order: "ALPHA ASC")))
  end

  on "admin" do
    run Admins
  end

  on "user" do
    run Users
  end

  on default do
    run Guests
  end
end
