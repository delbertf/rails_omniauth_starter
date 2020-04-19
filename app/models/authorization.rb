class Authorization < ApplicationRecord
	belongs_to :user
	validates :user_id, :provider, :uid, :presence => true

	def self.find_or_create(auth_hash)
	  unless auth = find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])
	  	unless user = User.find_by(email: auth_hash["info"]["email"])
	  		# user already exists? when not, create user
	    	user = User.create :name => auth_hash["info"]["name"], :email => auth_hash["info"]["email"]
    	end
	    auth = create :user => user, :provider => auth_hash["provider"], :uid => auth_hash["uid"]
	  end
	 
	  auth
	end
end
