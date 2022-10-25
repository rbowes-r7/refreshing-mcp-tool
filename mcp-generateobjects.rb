require 'set'

if ARGV.length != 1 && ARGV.length != 2
  $stderr.puts "Usage: ruby ./mcp-generateobjects <path to libmcpmsg.so> [0 = list, 1 = .h format]"
  exit 1
end

DO_HEADER = ARGV[1] && ARGV[1] == '1'

# Where we start our search (doubt this will change)
FIRST_ENTRY = 'eom'

# Read the file
LIBFILE = ARGV[0]
data = File.read(LIBFILE, :encoding => 'iso-8859-1')

# Convert to an int array
data_ints = data.unpack('V*')

# Quick sanity check - make sure there's only one 'eom'
count = data.scan(/#{FIRST_ENTRY}/).length
if count != 1
  $stderr.puts "Error: we need exactly one instance of '#{FIRST_ENTRY}' to find the first entry, and there were #{ count } instances!"
  exit 1
end

# Figure out where 'eom' is
offset_egg = data.index(FIRST_ENTRY)

# Figure out what points to it
count = data_ints.count(offset_egg)
if count != 1
  $stderr.puts "Error: More than one address in the file points to our 'eom' entry!"
  exit 1
end

index_start = data_ints.index(offset_egg)
index = 0

if DO_HEADER
  puts "typedef enum {"
  entries = Set.new()
end

loop do
  offset = data_ints[index_start + index]

  if data[offset].nil?
    break
  end

  entry = data[offset..].unpack('Z*')
  if !entry || entry.length == 0 || entry[0].length == 0 || entry[0] =~ /[^a-zA-Z0-9_]/
    break
  end
  entry = entry.pop

  if DO_HEADER
    entry.upcase!()

    if entries.include?(entry)
      affix = 200
      while entries.include?("#{ entry }_#{affix}")
        affix += 1
      end
      entry = "#{ entry }_#{affix},"
    end

    puts "  %s = 0x%04x," % [entry, index]
    entries.add(entry)
  else
    puts "0x%04x %s" % [index, entry]
  end

  index += 1
end

if DO_HEADER
  puts "} mcp_object_t;"
end
