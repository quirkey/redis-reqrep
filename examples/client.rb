require File.join(File.expand_path(File.dirname(__FILE__)), '../reqrep.rb')

puts "Reversing"
start = Time.now
reply = Reqrep.request_and_wait_for_reply(:reverse, {}, "Sally sells seashells")
puts reply.inspect
total = Time.now.to_f - start.to_f
puts "Took #{total * 1000}ms"
