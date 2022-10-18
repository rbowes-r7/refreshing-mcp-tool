require 'socket'
require './mcp-parser'

if ARGV.length < 2
  puts "Usage: ruby ./mcp-mitm.rb <your ip> <target ip> [listen port 1] [listen port 2]"
  puts
  puts "Note: ensure that `ssh root@<target ip>` works without user input.."
  puts "probably by setting up a password-less key. Sorry if that's annoying!"
  puts
  puts "Note2: this probably goes without saying, but this is semi-destructive"
  puts "(at the very least, interrupty) and should not be used on a production"
  puts "server (or any server you care about!)"
  exit 1
end

ME = ARGV[0]
TARGET = ARGV[1]
PORT1 = ARGV[2] || 1234
PORT2 = ARGV[3] || 1235
DO_SETUP = true

LISTENER1 = TCPServer.new(PORT1)
LISTENER2 = TCPServer.new(PORT2)

puts "Configuration (edit the script to change, this is a PoC!):"
puts
puts "Your IP: #{ ME }"
puts "Target IP: #{ TARGET }"
puts "Listening port 1: #{ PORT1 }"
puts "Listening port 2: #{ PORT2 }"
puts "SSH into the target to set things up: #{ DO_SETUP }"
if DO_SETUP
  puts "  (Make sure you can ssh into the host as root with no password)"
  puts "  (Yes yes, I know it's a PoC!)"
end

def handle(s1, s2)
  $stderr.puts
  $stderr.puts '---------------------------------------------------'
  $stderr.puts
  $stderr.puts "Received session @ #{ s1 } <--> #{ s2 }"

  Thread.new([s1, s2]) do |s|
    begin
      # Get the two sockets
      s1, s2 = s

      eof = [false, false]
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
          #$stderr.puts "Both sockets closed or EOF"
          return
        end

        if eof == [true, true]
          return
        end

        r, _, e = IO.select(read_array, nil, s)

        if e && e.length > 0
          raise "Socket[s] closed: #{ e }"
        end

        0.upto(1) do |i|
          if r && r.include?(s[i])
            if s[i].eof?
              #$stderr.puts "#{ s[i] } :: Reached EOF, will no longer read"
              read_array.delete(s[i])
              next
            end

            if header[i].length < 16
              #$stderr.puts "#{ s[i] } :: Receiving header"
              data = s[i].read_nonblock(16 - header[i].length())
              if data.nil?
                raise "#{ s[i] } :: Socket closed"
              end
              header[i] += data

              if header[i].length == 16
                #$stderr.puts "#{ s[i] } :: Received full header!"
                length[i] = header[i].unpack('N').pop
              end
            else
              #$stderr.puts "#{ s[i] } :: Receiving body"
              data = s[i].read_nonblock(length[i] - body[i].length)
              if data.nil?
                raise "#{ s[i] } :: socket closed"
              end
              body[i] += data
              if body[i].length == length[i]
                #$stderr.puts "#{ s[i] } :: Received full body! Writing it to #{ s[(i + 1) % 2] }"
                s[(i + 1) % 2].write_nonblock(header[i] + body[i])

                puts
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
      $stderr.puts "Ending thread"
      if !s1.nil?
        s1.close()
      end
      if !s2.nil?
        s2.close()
      end
    end
  end
end

begin
  # If we are doing setup, get things going (note: this breaks the server)
  if DO_SETUP
    puts "SSH'ing into the server to set things up"
    system("ssh root@#{TARGET} mv /var/run/mcp /var/run/mcp2")

    CONNECTION1 = Thread.new do
      system "ssh root@#{TARGET} socat -t100 TCP-CONNECT:#{ME}:#{PORT1},reuseaddr,fork UNIX-CONNECT:/var/run/mcp2"
      puts "Session 1 closed?"
    end

    CONNECTION2 = Thread.new do
      system "ssh root@#{TARGET} socat -t100 UNIX-LISTEN:/var/run/mcp,mode=777,reuseaddr,fork TCP-CONNECT:#{ME}:#{PORT2}"
      puts "Session 2 closed?"
    end

    puts "Ready!"
  else
    puts "You'll probably want to ssh into the host as root and run:"
    puts
    puts "# mv /var/run/mcp /var/run/mcp2"
    puts "# socat -t100 TCP-CONNECT:#{ME}:#{PORT1},reuseaddr,fork UNIX-CONNECT:/var/run/mcp2"
    puts "# socat -t100 UNIX-LISTEN:/var/run/mcp,mode=777,reuseaddr,fork TCP-CONNECT:#{ME}:#{PORT2}"
    puts
  end

  loop do

    s2 = LISTENER2.accept
    #$stderr.puts "Received connection 2: #{s2}"

    s1 = LISTENER1.accept
    #$stderr.puts "Received connection 1: #{s1}"

    handle(s1, s2)
  end
ensure
  if DO_SETUP
    puts "SSH'ing into the server to fix things"
    system("ssh root@#{TARGET} mv /var/run/mcp2 /var/run/mcp")
  else
    puts "You'll probably want to see into the host as root and run:"
    puts
    puts "mv /var/run/mcp2 /var/run/mcp"
  end

  if Object.const_defined?(:CONNECTION1) && CONNECTION1
    CONNECTION1.kill
  end

  if Object.const_defined?(:CONNECTION2) && CONNECTION2
    CONNECTION1.kill
  end
end
