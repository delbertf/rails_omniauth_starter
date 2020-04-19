# README

## 1. Prepare the application

Now open your Gemfile and reference the omniauth gem and the gem for the auth-provider you choose.

```
gem 'omniauth'
gem 'omniauth-facebook'
```

Next, per usual, run the bundle install command to install the gem.


## 2. Create a Provider

If you want to use Facebook authentication, head over to developers.facebook.com/apps and click on "Create New App". 


## 3. Add your Providers to the App

Since Rails 5.2, secrets or credentials are stored in a new encrypted file `config/credentials.yml.enc`. We need to add the AppID and the Secret Code from the auth-provider to this file. To do so, execute this command in your project folder. Note: I'm using SublimeText Editor, replace with your editor. 

`EDITOR='subl --wait' rails credentials:edit`

Add your credentials like this and close the editor.

```
facebook:
  access_app_id: 123
  secret_access_key: xyz
```

Keep in mind to back up your `config/master.key` and exclude it from version control. 

Create a new file under config/initializers called omniauth.rb. This acts as middleware and allows to configure our authentication process.

Paste the following code into the file we created earlier:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, YOUR_APP_ID, YOUR_APP_SECRET
end
```

This is all the configuration you need to get this going. The rest is taken care of by Omniauth, as we’re going to find in the next step.


## 4. Add Login Page

Next, we need a session controller with a new, create and failure method.

```
rails generate controller sessions new create failure
```

Open your `config/routes.rb` and add this:

```
get   '/login', :to => 'sessions#new', :as => :login
match '/auth/:provider/callback', :to => 'sessions#create'
match '/auth/failure', :to => 'sessions#failure'
```

Let’s break this down:

* The first line is used to create a simple login form where the user will see a simple "Connect with Facebook" link.
* The second line is to catch the provider’s callback. After a user authorizes your app, the provider redirects the user to this url, so we can make use of their data.
* The last one will be used when there’s a problem, or if the user didn’t authorize our application.

Make sure you delete the routes that were created automatically when you ran the rails generate command. They aren't necessary for this project.

Open your `app/controllers/sessions_controller.rb` file and write the create method, like so:

```
def create
  auth_hash = request.env['omniauth.auth']
 
  render :plain => auth_hash.inspect
end
```

This is used to make sure everything is working. Point your browser to localhost:3000/auth/facebook and you’ll be redirected to Facebook so you can authorize your app. Authorize it, and you will be redirected back to your app and see a hash with some information (in the console).

## 5. Create the User Model

Next, let's create the user model with just name and email:

```
rails generate model User name:string email:string
```

The idea behind out application is that a user can choose between using Facebook or Twitter (or any other provider) to sign up, so we need another model to store that information. Let’s create it:

```
rails generate model Authorization provider:string uid:string user_id:integer
```

Then, do a migration: `rails db:migrate`.

 A user will have one or more authorizations, and when someone tries to login using a provider, we simply look at the authorizations within the database and look for one which matches the uid and provider fields. This way, we also enable users to have many providers, so they can later login using Facebook, or Twitter, or any other provider they have configured!

 Add this to your `app/models/user.rb`

```
has_many :authorizations
validates :name, :email, :presence => true
```

This specifies that a user may have multiple authorizations, and that the name and email fields in the database are required.

Next, to your `app/models/authorization.rb` file, add:

```
belongs_to :user
validates :provider, :uid, :presence => true
```

Within this model, we designate that each authorization is bound to a specific user. We also set some validation as well. 

## 6. Add logic to our Session Controller

This logic signs the user in or creates the profile, depending on the case. Modify the `create` method in `app/controllers/sessions_controller.rb`

```
def create
  auth_hash = request.env['omniauth.auth']
 
  @authorization = Authorization.find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])
  if @authorization
    render :plain => "Welcome back #{@authorization.user.name}! You have already signed up."
  else
    user = User.new :name => auth_hash["info"]["name"], :email => auth_hash["info"]["email"]
    user.authorizations.build :provider => auth_hash["provider"], :uid => auth_hash["uid"]
    user.save
 
    render :plain => "Hi #{user.name}! You've signed up."
  end
end
```

Later we will refactor the code, but it's ok for now:
* We check whether an authorization exists for that provider and that uid. If one exists, we welcome our user back.
* If no authorization exists, we sign the user up. We create a new user with the name and email that the provider (Facebook in this case) gives us, and we associate an authorization with the provider and the uid we’re given.

Give it a test! Go to localhost:3000/auth/facebook and you should see "You’ve signed up". If you refresh the page, you should now see "Welcome back".

## 7. Enabling Multiple Providers

The ideal scenario would be to allow a user to sign up using one provider, and later add another provider so he can have multiple options to login with. Our app doesn’t allow that for now. We need to refactor our code a bit. Change your `sessions_controlller.rb` `create` method to look like this:

```
def create
  auth_hash = request.env['omniauth.auth']
 
  if session[:user_id]
    # Means our user is signed in. Add the authorization to the user
    User.find(session[:user_id]).add_provider(auth_hash)
 
    render :plain => "You can now login using #{auth_hash["provider"].capitalize} too!"
  else
    # Log him in or sign him up
    auth = Authorization.find_or_create(auth_hash)
 
    # Create the session
    session[:user_id] = auth.user.id
 
    render :plain => "Welcome #{auth.user.name}!"
  end
end
```

* If the user is already logged in, we’re going to add the provider they’re using to their account.
* If they’re not logged in, we’re going to try and find a user with that provider, or create a new one if it’s necessary.

We need to add a new method to the User and Authorization models. In the `user.rb` add:

```
def add_provider(auth_hash)
  # Check if the provider already exists, so we don't add it twice
  unless authorizations.find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])
    Authorization.create :user => self, :provider => auth_hash["provider"], :uid => auth_hash["uid"]
  end
end
```

In the `authorization.rb` add:

```
def self.find_or_create(auth_hash)
  unless auth = find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])
    user = User.create :name => auth_hash["user_info"]["name"], :email => auth_hash["user_info"]["email"]
    auth = create :user => user, :provider => auth_hash["provider"], :uid => auth_hash["uid"]
  end
 
  auth
end
```

To test another auth-provider follow these steps:

* add the auth-provider 'omniauth-twitter' to your Gemfile and bundle install
* Create the application in twitter and get application key and secret
* add app-key and app-secret to your encrypted credentials.yml.enc
* add auth-provider in your config/initializers/omniauth.rb

