# Oxidized Script
CLI and Library to interface with network devices in Oxidized

## Install
 % gem install oxidized-script

## Use

### CLI
```
[fisakytt@lan-login1 ~]% oxs S-2250220 'sh ver'
                Jan 29 2010 12:18:24
                K.14.54
                79
[fisakytt@lan-login1 ~]% cat > cmds
show ip route
[fisakytt@lan-login1 ~]% oxs -x cmds 62.236.123.199
Default gateway is 62.236.123.198

Host               Gateway           Last Use    Total Uses  Interface
ICMP redirect cache is empty
[fisakytt@lan-login1 ~]% cat >> cmds
sh ip cef
[fisakytt@lan-login1 ~]% cat cmds|oxs -x- 62.236.123.199
Default gateway is 62.236.123.198

Host               Gateway           Last Use    Total Uses  Interface
ICMP redirect cache is empty
%IPv4 CEF not running
[fisakytt@lan-login1 ~]% oxs --help
Usage: oxs [options] hostname [command]
    -m, --model         host model (ios, junos, etc), otherwise discovered from Oxidized source
    -x, --commands      commands file to be sent
    -u, --username      username to use
    -p, --password      password to use
    -t, --timeout       timeout value to use
    -e, --enable        enable password to use
    -d, --debug         turn on debugging
    -h, --help          Display this help message.
[fisakytt@lan-login1 ~]% 
```

### Library
```
[fisakytt@lan-login1 ~]% cat moi42.b 
#!/usr/bin/env ruby

require 'oxidized/script'

Oxidized::Config.load
Oxidized.setup_logger

Oxidized::Script.new(:host=>'62.236.123.199') do |oxs|
  puts oxs.cmd 'show mac address-table dynamic vlan 101'
end
[fisakytt@lan-login1 ~]% ./moi42.b 
          Mac Address Table
-------------------------------------------

Vlan    Mac Address       Type        Ports
----    -----------       --------    -----
 101    44d3.ca4c.383e    DYNAMIC     Gi0/1
[fisakytt@lan-login1 ~]% 
```

## TODO
  * Interactive use?
  * Tests+docs, as always :(
