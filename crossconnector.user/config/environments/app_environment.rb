App::CONFIG[:email_from] = 'Ryan Heneise'
App::CONFIG[:admin_email] = 'support@crossconnector.com'
App::CONFIG[:app_name] = 'CrossConnector'
App::CONFIG[:mail_charset] = 'utf-8'
App::CONFIG[:security_token_life_hours] = 24
App::CONFIG[:server_env] = "#{RAILS_ENV}"
App::CONFIG[:priority_countries] = ["United States", "Mexico", "Canada"]
App::CONFIG[:reserved_subdomains] =  ["w", "ww", "www", "secure", "admin", "blog", "help"]
App::CONFIG[:objects_per_page] = 10
App::CONFIG[:banned_words] = []