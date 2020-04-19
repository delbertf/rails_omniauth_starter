class SessionsController < ApplicationController
  def new
  end

  def create
  	auth_hash = request.env['omniauth.auth']

  	if session[:user_id]
  		# Means our user is signed in. Add the authorization to the user
  		User.find(session[:user_id]).add_provider(auth_hash)

  		render :plain => "You can now login using #{auth_hash["provider"].capitalize} too!"
		else
			# Log him in or sign him up
			auth = Authorization.find_or_create(auth_hash)

			# create the session
			session[:user_id] = auth.user.id

			render :plain => "Welcome #{auth.user.name}!"
		end
  end

  def failure
  end
end
