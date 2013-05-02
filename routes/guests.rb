class Guests < Cuba
  define do
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

    on "restaurant/:restaurant_id" do |restaurant_id|
      res.write mote("views/layout.mote",
        title: "Restaurant Details",
        content: mote("views/restaurant.mote",
          restaurant_id: restaurant_id))
    end

    on "search" do
      on param("restaurant") do |params|
        edit = params
        if Restaurant.find(:name => edit["name"]).empty?
          res.write mote("views/layout.mote",
              title: "Login",
              message: "Restaurant not found.",
              content: mote("views/home.mote",
                edit: edit))
        else
          restaurant_id = Restaurant.find(:name => edit["name"]).ids[0]
          res.write mote("views/layout.mote",
            title: "Restaurant Details",
            content: mote("views/restaurant.mote",
              restaurant_id: restaurant_id))
        end
      end
    end

    on "not_permitted" do
      res.write mote("views/layout.mote",
        title: "Restaurants",
        message: "You don't have permissions to perform this action.",
        content: mote("views/home.mote"))
    end
  end
end
