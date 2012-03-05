# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
Rails.application.config.session_store :cookie_store, :key => "_contestadors_session"
#ActionController::Base.session = {
#  :key         => '_contestadors_session',
#  :secret      => '4dd2799cdc7208e2574fd3c647ff2c99480429dfb5637429cae85030ea6e895033ffbcabc6d7549a882989842a9c48400fb40d4fa5f8d2f4308959eb5e64a235'
#}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
