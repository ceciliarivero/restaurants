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

admin = Nest.new("Admin")
user = Nest.new("User")
restaurant = Nest.new("Restaurant")

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

class Admin < Ohm::Model
  attribute :email
  attribute :password

  unique :email
end

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

class Comment < Ohm::Model
  attribute :body

  reference :user, :User
  reference :restaurant, :Restaurant
end

Cuba.define do
  on "signup" do
    on param("user") do |params|
      edit = EditUser.new(params)
      if edit.valid?
        begin
          edit.password = Digest::SHA1.hexdigest(edit.password)
          u = User.create(edit.attributes)
          u.save
          session[:user] = u.id
          res.write mote("views/layout.mote",
            title: "Successful Sign up!",
            user_id: u.id,
            content: mote("views/done.mote",
              restaurant_id: "",
              message: "Success! You have just signed up.",
              url: "/",
              button_message: "Back to restaurants"))
        rescue Ohm::UniqueIndexViolation
          user[:id].decr
          res.write mote("views/layout.mote",
            title: "Sign up",
            message: "This email address is already registered.",
            content: mote("views/signup.mote",
              edit: edit))
        end
      else
        res.write mote("views/layout.mote",
        title: "Sign up",
        message: "Invalid information. Please check the form and try again.",
        content: mote("views/signup.mote",
          edit: edit))
      end
    end
    edit = EditUser.new({})
    res.write mote("views/layout.mote",
      title: "Sign up",
      content: mote("views/signup.mote",
        edit: edit))
  end

  on "login" do
    on param("user") do |params|
      edit = EditUser.new(params)
      if User.with(:email, edit.email)
        user_id = user[:uniques][:email].hget(edit.email)
        if User[user_id].password == Digest::SHA1.hexdigest(edit.password)
          session[:user] = user_id
          res.redirect "/"
        else
          res.write mote("views/layout.mote",
            title: "Login",
            message: "Incorrect Password.",
            content: mote("views/login.mote",
              edit: edit))
        end
      else
        res.write mote("views/layout.mote",
            title: "Login",
            message: "This email is not registered.",
            content: mote("views/login.mote",
              edit: edit))
      end
    end
    edit = EditUser.new({})
    res.write mote("views/layout.mote",
      title: "Login",
      content: mote("views/login.mote",
        edit: edit))
  end

  on "logout" do
    session.delete(:user)
    res.redirect "/"
  end

  on "admin/login" do
    on param("admin") do |params|
      edit = EditAdmin.new(params)
      if Admin.with(:email, edit.email)
        admin_id = admin[:uniques][:email].hget(edit.email)
        if Admin[admin_id].password == Digest::SHA1.hexdigest(edit.password)
          session[:admin] = admin_id
          res.redirect "/"
        else
          res.write mote("views/layout.mote",
            title: "Admin Login",
            message: "Incorrect Password.",
            content: mote("views/admin_login.mote",
              edit: edit))
        end
      else
        res.write mote("views/layout.mote",
            title: "Admin Login",
            message: "This email is not registered as Admin.",
            content: mote("views/admin_login.mote",
              edit: edit))
      end
    end
    edit = EditAdmin.new({})
    res.write mote("views/layout.mote",
      title: "Admin Login",
      content: mote("views/admin_login.mote",
        edit: edit))
  end

  on "admin/logout" do
    session.delete(:admin)
    res.redirect "/"
  end

  on "edit_admin/:admin_id" do |admin_id|
    if session[:admin] == admin_id
      on param("admin") do |params|
        edit = EditAdmin.new(params)
        if (edit.password).empty?
          edit.password = Admin[admin_id].password
        else
          edit.password = Digest::SHA1.hexdigest(edit.password)
        end
        if edit.valid?
          Admin[admin_id].update(edit.attributes)
          res.write mote("views/layout.mote",
            title: "Admin edited",
            content: mote("views/done.mote",
              admin_id: admin_id,
              restaurant_id: "",
              message: "Admin edited.",
              button_message: "Back to restaurants",
              url: "/"))
        else
          res.write mote("views/layout.mote",
            title: "Edit Admin",
            message: "Invalid information. Please check the form and try again.",
            content: mote("views/edit_admin.mote",
              admin: admin,
              admin_id: admin_id))
        end
      end
      res.write mote("views/layout.mote",
        title: "Edit Admin",
        content: mote("views/edit_admin.mote",
          admin: admin,
          admin_id: admin_id))
    else
      res.redirect "/not_permitted"
    end
  end

  on "add_restaurant" do
    if session[:admin]
      on param("restaurant") do |params|
        edit = EditRestaurant.new(params)
        if edit.valid?
          restaurant = Restaurant.create(edit.attributes)
          res.write mote("views/layout.mote",
            title: "New restaurant added",
            content: mote("views/done.mote",
              restaurant_id: "",
              message: "New restaurant added.",
              url: "/",
              button_message: "Back to restaurants list"))
        else
          res.write mote("views/layout.mote",
            title: "Add restaurant",
            message: "Invalid information. Please check the form and try again.",
            content: mote("views/add_restaurant.mote",
              edit: edit))
        end
      end
      edit = EditRestaurant.new({})
      res.write mote("views/layout.mote",
        title: "Add restaurant",
        content: mote("views/add_restaurant.mote",
          edit: edit))
    else
      res.redirect "/not_permitted"
    end
  end

  on "restaurant/:restaurant_id" do |restaurant_id|
    res.write mote("views/layout.mote",
      title: "Restaurant Details",
      content: mote("views/restaurant.mote",
        restaurant_id: restaurant_id,
        user: user,
        restaurant: restaurant))
  end

  on "edit_restaurant/:restaurant_id" do |restaurant_id|
    if session[:admin]
      on param("restaurant") do |params|
        edit = EditRestaurant.new(params)
        if edit.valid?
          Restaurant[restaurant_id].update(edit.attributes)
          res.write mote("views/layout.mote",
            title: "Restaurant edited",
            content: mote("views/done.mote",
              restaurant_id: restaurant_id,
              message: "Restaurant edited.",
              url: "/restaurant/",
              button_message: "Back to restaurant"))
        else
          res.write mote("views/layout.mote",
            title: "Edit restaurant",
            message: "Invalid information. Please check the form and try again.",
            content: mote("views/edit_restaurant.mote",
              restaurant_id: restaurant_id,
              restaurant: restaurant))
        end
      end
      res.write mote("views/layout.mote",
        title: "Edit restaurant",
        content: mote("views/edit_restaurant.mote",
          restaurant_id: restaurant_id,
          restaurant: restaurant))
    else
      res.redirect "/not_permitted"
    end
  end

  on "delete/:restaurant_id" do |restaurant_id|
    if session[:admin]
      Restaurant[restaurant_id].delete
      res.write mote("views/layout.mote",
        title: "Restaurant deleted",
        content: mote("views/done.mote",
          restaurant_id: "",
          message: "Restaurant deleted.",
          url: "/",
          button_message: "Back to restaurants list"))
    else
      res.redirect "/not_permitted"
    end
  end

  on "delete_comment/:restaurant_id/:comment" do |restaurant_id, comment|
    if session[:admin]
      Comment[comment].delete
      res.write mote("views/layout.mote",
        title: "Restaurant deleted",
        content: mote("views/done.mote",
          restaurant_id: restaurant_id,
          message: "Comment deleted.",
          url: "/restaurant/",
          button_message: "Back to restaurant"))
    else
      res.redirect "/not_permitted"
    end
  end

  on "users" do
    if session[:admin]
      res.write mote("views/layout.mote",
        title: "Manage Users",
        content: mote("views/users.mote",
          user: user))
    else
      res.redirect "/not_permitted"
    end
  end

  on "edit_user/:user_id" do |user_id|
    if session[:admin] || session[:user] == user_id
      on param("user") do |params|
        edit = EditUser.new(params)
        if (edit.password).empty?
          edit.password = User[user_id].password
        else
          edit.password = Digest::SHA1.hexdigest(edit.password)
        end
        if edit.valid?
          User[user_id].update(edit.attributes)
          if session[:admin]
            res.write mote("views/layout.mote",
              title: "User edited",
              content: mote("views/done.mote",
                restaurant_id: "",
                message: "User edited.",
                button_message: "Back to users",
                url: "/users"))
          elsif session[:user]
            res.write mote("views/layout.mote",
              title: "User edited",
              content: mote("views/done.mote",
                restaurant_id: "",
                message: "User edited.",
                button_message: "Back to restaurants",
                url: "/"))
          end
        else
          res.write mote("views/layout.mote",
            title: "Edit user",
            message: "Invalid information. Please check the form and try again.",
            content: mote("views/edit_user.mote",
              user: user,
              user_id: user_id))
        end
      end
      res.write mote("views/layout.mote",
              title: "Edit user",
              content: mote("views/edit_user.mote",
                user: user,
                user_id: user_id))
    else
      res.redirect "/not_permitted"
    end
  end

  on "remove_user/:user_id" do |user_id|
    if session[:admin]
      User[user_id].comments.each { |c| c.delete }
      User[user_id].delete
      res.write mote("views/layout.mote",
        title: "User removed",
        content: mote("views/done.mote",
          restaurant_id: "",
          message: "User removed.",
          url: "/users",
          button_message: "Back"))
    else
      res.redirect "/not_permitted"
    end
  end

  on "add_comment/:restaurant_id/:user_id" do |restaurant_id, user_id|
    if session[:user] == user_id
      on param("comment") do |params|
        edit = EditComment.new(params)
        if edit.valid?
          h = edit.attributes
          h[:user_id] = user_id
          h[:restaurant_id] = restaurant_id
          Comment.create(h)
          res.write mote("views/layout.mote",
            title: "New comment added",
            content: mote("views/done.mote",
              restaurant_id: restaurant_id,
              message: "New comment added.",
              url: "/restaurant/",
              button_message: "Back to restaurant"))
        else
          res.write mote("views/layout.mote",
            title: "Add comment",
            message: "It looks like you haven't written anything! Please add your comment.",
            content: mote("views/add_comment.mote",
              restaurant_id: restaurant_id,
              user_id: user_id,
              restaurant: restaurant,
              edit: edit))
        end
      end
      edit = EditComment.new({})
      res.write mote("views/layout.mote",
        title: "Add comment",
        content: mote("views/add_comment.mote",
          restaurant_id: restaurant_id,
          user_id: user_id,
          restaurant: restaurant,
          edit: edit))
    else
      res.redirect "/not_permitted"
    end
  end

  on "not_permitted" do
    res.write mote("views/layout.mote",
      title: "Restaurants",
      message: "You don't have permissions to perform this action.",
      content: mote("views/home.mote",
        restaurant: restaurant))
  end

  on default do
    res.write mote("views/layout.mote",
      title: "Restaurants",
      user_id: session[:user],
      admin_id: session[:admin],
      content: mote("views/home.mote",
        restaurant: restaurant))
  end
end