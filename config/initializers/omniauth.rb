Rails.application.config.middleware.use OmniAuth::Builder do
	provider :facebook, Rails.application.credentials.facebook[:access_app_id], Rails.application.credentials.facebook[:secret_access_key]
	provider :twitter, Rails.application.credentials.twitter[:access_app_id], Rails.application.credentials.twitter[:secret_access_key]
end