class Users < Cuba
  define do
    on "login" do
      on param("user") do |params|
        user = User.with(:email, params["email"]) unless nil
        if user && user.password == Digest::SHA1.hexdigest(params["password"])
          session[:user] = user.id
          res.redirect "/"
        else
          res.write mote("views/layout.mote",
          title: "Login",
          message: "Email or password are incorrect.",
          content: mote("views/login.mote",
            params: params))
        end
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
                user_id: user_id))
          end
        end
        res.write mote("views/layout.mote",
                title: "Edit user",
                content: mote("views/edit_user.mote",
                  user_id: user_id))
      else
        res.redirect "/not_permitted"
      end
    end

    on "not_permitted" do
      res.write mote("views/layout.mote",
        title: "Restaurants",
        message: "You don't have permissions to perform this action.",
        content: mote("views/home.mote"))
    end

    on "logout" do
      session.delete(:user)
      res.redirect "/"
    end

    on default do
      res.write mote("views/layout.mote",
        title: "Login",
        content: mote("views/login.mote",
          params: ""))
    end
  end
end
