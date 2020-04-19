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

