Rails.application.configure do
  config.action_mailer.default_url_options = {
    :host => 'localhost',
    :port => 8000
  }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'localhost',
    port:                 465,
    domain:               'localhost',
    user_name:            'ss34',
    password:             '***REMOVED***',
    authentication:       :login,
    enable_starttls_auto: true,
    ssl: true  }
end