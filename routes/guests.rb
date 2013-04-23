class Guests < Cuba
  define do
    user = Nest.new("User")
    restaurant = Nest.new("Restaurant")
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

      on default do
        edit = EditUser.new({})
        res.write mote("views/layout.mote",
          title: "Login",
          content: mote("views/login.mote",
            edit: edit))
      end
    end

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

      on default do
        edit = EditUser.new({})
        res.write mote("views/layout.mote",
          title: "Sign up",
          content: mote("views/signup.mote",
            edit: edit))
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
        on default do
          res.write mote("views/layout.mote",
            title: "Add comment",
            content: mote("views/add_comment.mote",
              restaurant_id: restaurant_id,
              user_id: user_id,
              restaurant: restaurant,
              edit: edit))
        end
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
                  url: "/admin/users"))
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

    on "restaurant/:restaurant_id" do |restaurant_id|
      res.write mote("views/layout.mote",
        title: "Restaurant Details",
        content: mote("views/restaurant.mote",
          restaurant_id: restaurant_id,
          user: user,
          restaurant: restaurant))
    end

    on "not_permitted" do
      res.write mote("views/layout.mote",
        title: "Restaurants",
        message: "You don't have permissions to perform this action.",
        content: mote("views/home.mote",
          restaurant: restaurant))
    end

    on "logout" do
      session.delete(:user)
      res.redirect "/"
    end
  end
end
