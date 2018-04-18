require 'sinatra'
require 'json'
require_relative 'kruskal'
require_relative 'email'
require_relative 'steganography'

post '/email' do
  file = File.open('emails.txt', 'w')
  file.write(params['emails'][:tempfile].read)
  file.close
  sort_email = Sort.new('emails.txt', 'sorted.txt')
  sort_email.sort
  send_file 'sorted.txt'
end

post '/kruskal' do
  content_type :json
  graph = JSON.parse(request.body.read)
  kruskal = MST.new(graph)
  kruskal.get_mst.to_json
end

post '/hide-message' do
  image = params['image'][:tempfile].read
  message = params['message']
  steg = Steganography.new
  data = image.unpack('C*')
  steg.hide_message(data, message)
  mod = File.new('modify.bmp', 'w')
  mod.close
  IO.binwrite('modify.bmp', data.pack('C*'))
  send_file 'modify.bmp'
end

post '/extract-message' do
  image = params['image'][:tempfile].read
  steg = Steganography.new
  message = steg.extract_message(image.unpack('C*'))
  message.pack('C*')
end
