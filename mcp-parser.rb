# Parse the objects file into a tag->name array
TAGS_BY_ID = File.read('./mcp-objects.txt')
  .split(/\n/)
  .select { |s| !s.start_with?('#') && s.include?(' ') }
  .map do |l|
    tag, name = l.split(/ /)

    [ tag.to_i(16), name ]
  end.to_h

# This won't be 100% reliable, so probably don't block on it
def parse(stream, depth = 0)
  # Reminder: this has to be an array, not a hash, because there are
  # often duplicate entries (like multiple userdb_entry results when a
  # query is performed).
  result = []

  # Padding for indents
  padding = ' ' * depth

  # Make a Hash of parsers. Some of them are recursive, which is fun!
  #
  # They all take the tag + stream as an input argument, and return
  # the remainder of the stream
  parsers = {
    # The easy stuff - simple values
    'ulong' => proc do |tag, s|
      value, s = s.unpack('Na*')
      puts "#{padding}#{tag} (ulong) = 0x%08x (%d)" % [value, value]
      s
    end,

    'long' => proc do |tag, s|
      value, s = s.unpack('Na*')
      puts "#{padding}#{tag} (long) = 0x%08x (%d)" % [value, value]
      s
    end,

    'uquad' => proc do |tag, s|
      value, s = s.unpack('Q>a*')
      puts "#{padding}#{tag} (uquad) = 0x%016x (%d)" % [value, value]
      s
    end,

    'uword' => proc do |tag, s|
      value, s = s.unpack('na*')
      puts "#{padding}#{tag} (uword) = 0x%04x (%d)" % [value, value]
      s
    end,

    'byte' => proc do |tag, s|
      value, s = s.unpack('Ca*')
      puts "#{padding}#{tag} (byte) = 0x%02x (%d)" % [value, value]
      s
    end,

    'service' => proc do |tag, s|
      value, s = s.unpack('na*')
      puts "#{padding}#{tag} (service) = 0x%04x (%d)" % [value, value]
      s
    end,


    # Parse 'time' as a time
    'time' => proc do |tag, s|
      value, s = s.unpack('Na*')
      puts "#{padding}#{tag} (time) = #{Time.at(value)}"
      s
    end,

    # Look up 'tag' values
    'tag' => proc do |tag, s|
      value, s = s.unpack('na*')
      puts "#{padding}#{tag} (tag) = #{TAGS_BY_ID[value] || "Unknown tag: 0x%04x" % value}"
      s
    end,

    # Parse MAC addresses
    'mac' => proc do |tag, s|
      value, s = s.unpack('a6a*')
      puts "#{padding}#{tag} (mac) = #{value.bytes.map { |b| '%02x' % b }.join(':')}"
      s
    end,

    # 'string' is prefixed by two length values
    'string' => proc do |tag, s|
      length, otherlength, s = s.unpack('Nna*')

      # I'm sure the two length values have a semantic difference, but just check for sanity
      if otherlength + 2 != length
        raise "Inconsistent string lengths: #{length} + #{otherlength}"
      end

      value, s = s.unpack("a#{otherlength}a*")
      puts "#{padding}#{tag} (string) = #{value}"
      s
    end,

    # 'structure' is recursive
    'structure' => proc do |tag, s|
      length, s = s.unpack('Na*')
      struct, s = s.unpack("a#{length}a*")

      puts "#{padding}#{tag} (structure) (#{length} bytes):"
      parse(struct, depth + 1)
      s
    end,

    # 'array' is a bunch of consecutive values of the same type, which
    # means we need to index back into this same parser array
    'array' => proc do |tag, s|
      length, s = s.unpack('Na*')
      array, s = s.unpack("a#{length}a*")

      type, elements, array = array.unpack('nNa*')
      type = TAGS_BY_ID[type] || '<unknown type 0x%04x>' % type

      puts "#{padding}#{tag} (array) (#{elements} #{type} elements):"
      padding += ' '

      if parsers[type]
        elements.times do
          array = parsers[type].call(tag, array)
        end
      else
        puts "#{padding}(don't know how to parse type #{type})"
      end

      padding[0] = ''

      s
    end
  }

  begin
    while stream.length > 2
      tag, type, stream = stream.unpack('nna*')

      tag = TAGS_BY_ID[tag] || '<unknown tag 0x%04x>' % tag
      type = TAGS_BY_ID[type] || '<unknown type 0x%04x>' % type

      if parsers[type]
        stream = parsers[type].call(tag, stream)
      else
        raise "Tried to parse unknown mcp type (skipping): type = #{type}, tag = #{tag}"
      end
    end
  rescue StandardError => e
    # If we fail somewhere, print a warning but return what we have
    $stderr.puts "Parsing mcp data failed: #{e.message}"
  end

  result
end

def parse_stream(stream)
  while stream.length > 0
    length, header, stream = stream.unpack('Na12a*')
    packet, stream = stream.unpack("a#{ length }a*")
    parse(packet)
  end
end

if __FILE__ == $0
  parse_stream($stdin.read())
end
