Recaptcha.configure do |config|
  config.public_key  = CONFIG['recaptcha_pub_key']
  config.private_key = CONFIG['recaptcha_priv_key']
end
