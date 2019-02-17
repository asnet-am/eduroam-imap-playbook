For Remote access first in /etc/ansible/hosts
add your hosts as follows

[frsthost]

192.168.1.2 

[scndhost]

192.168.1.3

Notice: The hostnames and ip addresses need to be changed

in root/eduroam-imap-playbook/inventories/development
comment or delete: local ansible_connection=local as follows
#local	ansible_connection=local

and add
frsthost ansible_port=22 ansible_host=192.168.1.2
scndhost ansible_port=22 ansible_host=192.168.1.3

the same needs to be done here 
[eduroam-imap]
comment or delete: localhost as follows
#localhost

and add
frsthost 
scndhost
