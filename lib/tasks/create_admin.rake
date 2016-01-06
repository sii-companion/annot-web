task :create_admin, [:username, :email, :password] => :environment do |t, args|
    puts args.inspect
    username = args[:username]
    password = args[:password]
    email = args[:email]
    if username.nil? or password.nil? or email.nil? then
      STDERR.puts('Missing email, username, or password. use "create_admin\[foo,test@example.com,secret\]')
      exit(1)
    end
    u = User.find_by_name(username)
    if u then
      STDERR.puts "Found existing user #{username}, removing..."
      u.destroy
    end
    u = User.new(name: username, fullname: 'Admin User', password: password, email: email)
    if u.save! then
      STDERR.puts "User #{username} with email #{email} created successfully."
    end
    STDERR.puts "done"
end