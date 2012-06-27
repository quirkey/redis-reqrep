require File.join(File.expand_path(File.dirname(__FILE__)), '../reqrep.rb')

app = Reqrep::App.new

app.on :reverse do |request|
  request.body.to_s.reverse
end

app.on :sleep do |request|
  if time = request.headers['sleep']
    time = time.to_i
  else
    time = 5
  end
  sleep time
  "Done sleeping"
end

app.on :random_id do |request|
  [:yup, {}, rand(Time.now.to_i)]
end

puts "Listening"
app.run!
