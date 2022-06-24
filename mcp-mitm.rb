# Kinda from https://gist.github.com/rdp/4956520

require 'socket'
require './mcp-parser'

if ARGV.length != 3
  $stderr.puts "Usage: mcp-mitm.rb <listen port> <upstream host> <upstream port>"
  exit 1
end

LISTEN, UPSTREAM_HOST, UPSTREAM_PORT = (ARGV[0] || 1234).to_i, ARGV[1] || 'f5', (ARGV[2] || 1234).to_i

# This can go in either direction
# def handler(incoming, outgoing)
#   $stderr.puts "Reading header"
#   header = incoming.read(16)
#   if header.nil?
#     raise "Stream closed"
#   end

#   if header.length < 16
#     raise "Didn't receive the full header!"
#   end

#   packet_length = header.unpack('N').pop

#   $stderr.puts "Reading #{ packet_length }-byte body"
#   packet = incoming.read(packet_length)

#   begin
#     parse(packet)
#   rescue StandardError => e
#     $stderr.puts "Error parsing message: #{ e }"
#   ensure
#     outgoing.write(header + packet)
#   end
# end

listener = TCPServer.new(LISTEN)

while(new_socket = listener.accept())
  $stderr.puts "Received connection @ #{ new_socket }"

  Thread.new(new_socket) do |s1|
    begin
      $stderr.puts "Connecting upstream: #{ UPSTREAM_HOST }:#{ UPSTREAM_PORT }"
      s2 = TCPSocket.new(UPSTREAM_HOST, UPSTREAM_PORT)
      $stderr.puts "Connected upstream @ #{ s2 }!"


      eof = [false, false]
      s = [s1, s2]
      read_array = [s1, s2]
      header = ['', '']
      body = ['', '']
      length = [0, 0]

      s.each do |so|
        so.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        so.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPIDLE, 50)
        so.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPINTVL, 10)
        so.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPCNT, 5)
      end

      outgoing = ['', '']

      while(true) do
        if s1.closed? && s2.closed?
          $stderr.puts "Both sockets closed or EOF"
          break
        end

        r, _, e = IO.select(read_array, nil, s)

        if e && e.length > 0
          raise "Socket[s] closed: #{ e }"
        end

        0.upto(1) do |i|
          if r && r.include?(s[i])
            if s[i].eof?
              $stderr.puts "#{ s[i] } :: Reached EOF, will no longer read"
              read_array.delete(s[i])
              next
            end

            if header[i].length < 16
              $stderr.puts "#{ s[i] } :: Receiving header"
              data = s[i].read_nonblock(16 - header[i].length())
              if data.nil?
                raise "#{ s[i] } :: Socket closed"
              end
              header[i] += data

              if header[i].length == 16
                $stderr.puts "#{ s[i] } :: Received full header!"
                length[i] = header[i].unpack('N').pop
              end
            else
              $stderr.puts "#{ s[i] } :: Receiving body"
              data = s[i].read_nonblock(length[i] - body[i].length)
              if data.nil?
                raise "#{ s[i] } :: socket closed"
              end
              body[i] += data
              if body[i].length == length[i]
                $stderr.puts "#{ s[i] } :: Received full body! Writing it to #{ s[(i + 1) % 2] }"
                s[(i + 1) % 2].write_nonblock(header[i] + body[i])
                parse(body[i])
                $stdout.flush()
                header[i] = ''
                body[i] = ''
                length[i] = 0
              end
            end
          end
        end
      end
    rescue StandardError => e
      $stderr.puts "Error: #{ e }"
    ensure
      if !s1.nil?
        s1.close()
      end
      if !s2.nil?
        s2.close()
      end
    end
  end
end
