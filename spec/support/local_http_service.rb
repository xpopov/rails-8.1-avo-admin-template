require "socket"

module LocalHttpService
  def with_local_http_service(responses)
    server = TCPServer.new("127.0.0.1", 0)
    worker = Thread.new do
      responses.each do |status, body|
        socket = server.accept
        begin
          while (line = socket.gets) && line != "\r\n"
          end
          socket.write("HTTP/1.1 #{status} Response\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
        ensure
          socket.close
        end
      end
    end
    yield URI("http://127.0.0.1:#{server.addr[1]}/status")
  ensure
    worker&.join(2) || worker&.kill&.join
    server&.close
  end
end

RSpec.configure do |config|
  config.include LocalHttpService
end
