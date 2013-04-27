class Admins < Cuba
  define do
    on "login" do
      on param("admin") do |params|
        edit = EditAdmin.new(params)
        if edit.valid? && Admin.with(:email, edit.email) &&
          Admin.with(:email, edit.email).password == Digest::SHA1.hexdigest(edit.password)
            session[:admin] = Admin.with(:email, edit.email).id
            res.redirect "/"
        else
          res.write mote("views/layout.mote",
          title: "Edit Admin",
          message: "Email or password are incorrect.",
          content: mote("views/admin_login.mote",
            edit: edit))
        end
      end
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
        on default do
          res.write mote("views/layout.mote",
            title: "Edit Admin",
            content: mote("views/edit_admin.mote",
              admin_id: admin_id))
        end
      else
        res.redirect "/admin/not_permitted"
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
        on default do
          edit = EditRestaurant.new({})
          res.write mote("views/layout.mote",
            title: "Add restaurant",
            content: mote("views/add_restaurant.mote",
              edit: edit))
        end
      else
        res.redirect "/admin/not_permitted"
      end
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
                restaurant_id: restaurant_id))
          end
        end
        on default do
          res.write mote("views/layout.mote",
            title: "Edit restaurant",
            content: mote("views/edit_restaurant.mote",
              restaurant_id: restaurant_id))
        end
      else
        res.redirect "/admin/not_permitted"
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
        res.redirect "/admin/not_permitted"
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
        res.redirect "/admin/not_permitted"
      end
    end

    on "users" do
      if session[:admin]
        edit = SearchUsers.new({})
        res.write mote("views/layout.mote",
          title: "Manage Users",
          content: mote("views/users.mote",
            edit: edit))
      else
        res.redirect "/admin/not_permitted"
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
            url: "/admin/users",
            button_message: "Back"))
      else
        res.redirect "/admin/not_permitted"
      end
    end

    on "search_users" do
      if session[:admin]
        on param("user") do |params|
          edit = SearchUsers.new(params)
          if edit.valid?
            if User.with(:email, edit.email)
              user_id = User.with(:email, edit.email).id
              res.write mote("views/layout.mote",
                title: "User Details",
                content: mote("views/user.mote",
                  user_id: user_id,
                  edit: edit))
            else
              res.write mote("views/layout.mote",
                  title: "Manage Users",
                  message: "User not found.",
                  content: mote("views/users.mote",
                    edit: edit))
            end
          else
            res.write mote("views/layout.mote",
              title: "Manage Users",
              message: "Invalid information. Please check your input and try again.",
              content: mote("views/users.mote",
                edit: edit))
          end
        end
      else
        res.redirect "/admin/not_permitted"
      end
    end

    on "not_permitted" do
      res.write mote("views/layout.mote",
        title: "Restaurants",
        message: "You don't have permissions to perform this action.",
        content: mote("views/home.mote"))
    end

    on "logout" do
      session.delete(:admin)
      res.redirect "/"
    end

    on default do
      edit = EditAdmin.new({})
      res.write mote("views/layout.mote",
        title: "Admin Login",
        content: mote("views/admin_login.mote",
          edit: edit))
    end
  end
end
