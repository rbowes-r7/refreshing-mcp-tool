# Parse the objects file into a tag->name array
TAGS = File.read('./mcp-objects.txt')
  .split(/\n/)
  .select { |s| !s.start_with?('#') && s.include?(' ') }
  .map do |l|
    tag, name = l.split(/ /)

    [ tag.to_i(16), name ]
  end.to_h

# This won't be 100% reliable, so probably don't block on it
def parse(stream, depth = 0)
  s = " " * depth

  begin
    while stream.length > 2
      tag, type, stream = stream.unpack('nna*')

      # puts "%04x : %04x" % [tag, type]
      tag  = TAGS[tag]  || '<unknown tag>'
      type = TAGS[type] || '<unknown tag>'

      if type == 'structure'
        # Get the length and struct data, then recurse
        length, stream = stream.unpack('Na*')
        struct, stream = stream.unpack("a#{ length }a*")

        puts "#{s}#{tag} (#{type}):"
        parse(struct, depth + 1)
      elsif type == 'string'
        length, otherlength, stream = stream.unpack('Nna*')

        # I'm sure the two length values have a semantic difference, but just check for sanity
        if otherlength + 2 != length
          raise "Inconsistent string lengths: #{ length } + #{ otherlength }"
        end

        str, stream = stream.unpack("a#{ otherlength }a*")
        puts "#{s}#{tag} (#{type}) = \"#{ str }\""
      elsif type == 'uquad'
        value, stream = stream.unpack('Q>a*')
        puts "#{s}#{tag} (#{type}) = 0x%016x (%d)" % [value, value]
      elsif type == 'ulong'
        value, stream = stream.unpack('Na*')
        puts "#{s}#{tag} (#{type}) = 0x%08x (%d)" % [value, value]
      elsif type == 'time'
        value, stream = stream.unpack('Na*')
        puts "#{s}#{tag} (#{type}) = %s (%d)" % [Time.at(value), value]
      elsif type == 'uword'
        value, stream = stream.unpack('na*')
        puts "#{s}#{tag} (#{type}) = 0x%04x (%d)" % [value, value]
      elsif type == 'long'
        value, stream = stream.unpack('Na*')
        puts "#{s}#{tag} (#{type}) = 0x%08x (%d)" % [value, value]
      elsif type == 'tag'
        value_tag, stream = stream.unpack('na*')
        puts "#{s}#{tag} (#{type}) = #{ TAGS[value_tag] || '<unknown tag>' }"
      elsif type == 'byte'
        value_tag, stream = stream.unpack('Ca*')
        puts "#{s}#{tag} (#{type}) = #{ TAGS[value_tag] || '<unknown tag>' }"
      elsif type == 'mac'
        value, stream = stream.unpack('a6a*')
        value = value.bytes.map { |b| '%02x' % b }.join(':')
        puts "#{s}#{tag} (#{type}) = #{ value }"
      elsif type == 'array'
        length, stream = stream.unpack('Na*')
        array, stream = stream.unpack("a#{ length }a*")

        puts "#{s}#{tag} (#{type}): Array data: #{ array.unpack('H*').pop }"
      else
        raise "Unknown type: #{ type }"
        return
      end
    end
  rescue StandardError => e
    puts "#{s}** #{ e.message }"
    puts "#{s}** Unparsed: #{ stream.unpack('H*') }"
  end

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
