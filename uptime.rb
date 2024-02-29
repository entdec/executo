require "curb"

http = Curl.get("http://www.google.com/")
puts http.body_str
