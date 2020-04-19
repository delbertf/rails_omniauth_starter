Rails.application.routes.draw do
	get '/login', :to => 'sessions#new', :as => :login
	get '/auth/:provider/callback', :to => 'sessions#create'
	get '/auth/failure', :to => 'sessions#failure'
	get '/logout', :to => 'sessions#destroy'
end
