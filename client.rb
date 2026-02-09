require "bundler/inline"

gemfile do
    source "http://rubygems.org"
    gem "faraday"

    # https://github.com/lostisland/faraday-multipart
    gem "faraday-multipart"
end

require "faraday"
require "faraday/multipart"

server = Faraday.new("http://localhost:4567") do |f|
  f.request :multipart
end
server.set_basic_auth "bob", "pwdb"
data = {
  password: "demo",
 options:"flip",
 #options: '{"flip": true, "font": "small"}',
  original_file: Faraday::Multipart::FilePart.new("toto.txt", "text/plain")
}

puts "=== CREATION fichier  ==="
response = server.post("/files", data) 
puts(response.body)

uuid = "30ead739-2551-4f76-9ff9-e38bd265555a"
puts "=== MODIFIER mot de passe ==="
response = server.patch("/files/#{uuid}") do |req|
  req.body = "DISMOIOI3"  # Mot de passe DIRECT dans body
end
puts "Status: #{response.status}"  

uuid = "ef30d60d-4026-4765-8519-016b730e8225"
puts "=== SUPPRESSION fichier ==="
response = server.delete("/files/#{uuid}")
puts "Status: #{response.status}"  