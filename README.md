# eduroam-imap-playbook Ansible playbook

This is an [Ansible playbook](http://docs.ansible.com/ansible/latest/playbooks.html) to set up [eduroam](https://eduroam.org/) authentication against an IMAP server.

The concept should allow users to authenticate on eduroam via their organization's IMAP server, including corporate IMAP servers, as well as [Google GSuite](https://gsuite.google.com/).

## Using the playbook

To use the playbook follow to commands below:

For installing git and ansible
```bash
apt install git ansible
```

For cloning the playbook
```bash
git clone https://github.com/asnet-am/eduroam-imap-playbook
```

For running the playbook
```bash
cd eduroam-imap-playbook
ansible-playbook -i inventories/development site.yml
```
All configuration happens in [group_vars/all](group_vars/all). You should edit that file to suit your enviroment. For more information read [group_vars/README.md](group_vars/README.md)

The playbook is also (hopefully) self documenting, allowing people who don't make use of Ansible to follow the configuration.

## Roles

This playbook contains a number of roles, all of which should be usable independently and outside of the playbook.

### [pam-imap](roles/pam-imap)

The **pam-imap** role downloads, compiles, installs, and configures the [pam-imap](https://github.com/wdoekes/pam-imap) pluggable authentication module. This PAM module allows for authentication against an IMAP server. By default, this is configured to be `imap.gmail.com`. See the [documentation](roles/pam-imap/README.md) for how to change this.

### [freeradius-eduroam](roles/freeradius-eduroam)

The **freeradius-eduroam** role installs and configures FreeRADIUS for eduroam EAP authentication. In the context of this IMAP playbook, it configures it to use PAM as an authentication backend.

The configuration (and the structure of the role) largely follow the GÉANT documentation for [eduroam service providers](https://wiki.geant.org/display/H2eduroam/freeradius-sp) and [eduroam identity providers](https://wiki.geant.org/display/H2eduroam/freeradius-idp). There are some minor differences to reflect later versions of FreeRADIUS, and to leave a little documentation in place. In addition, the role defaults to creating configuration relevant to the [South African NRO](https://eduroam.ac.za/). However, the [documentation](roles/freeradius-eduroam/README.md) explains how to change this.

### [eapol_test](roles/eapol_test)

The **eapol_test** role builds and installs the [eapol_test](http://deployingradius.com/scripts/eapol_test/) and [rad_eap_test](https://github.com/CESNET/rad_eap_test) utilities. These are useful for testing and debugging (see below).

## Additional configuration

There are a couple of things that are not configured by the playbook and may require additional configuration.

* **Remote Access** -- For remote access read the [eduroam-imap-playbook/inventories/README.md](inventories/README.md)

* **IMAP SSL Certificate** -- if your IMAP server does not use a certificate that's in the trust store for your server, you may need to supply the certificate and configure [roles/pam-imap/templates/pam_imap.conf.j2](roles/pam-imap/templates/pam_imap.conf.j2) accordingly.

* **EAP SSL Certificate** -- the role uses the default certificates created by the Ubuntu FreeRADIUS package. You may want to replace these.

## Testing

You can test the PAM component like this:

```bash
pamtester pam-imap-radius $USERNAME authenticate
```

You can test the inner EAP tunnel line this:

```bash
radtest -t pap $USERNAME@$REALM $PASSWORD localhost:18121 0 testing123
```

A complete EAP test can be done with eapol_test and rad_eap_test like this:

```bash
rad_eap_test -H localhost -P 1812 -S testing123 -u $USERNAME@$REALM -A anon
ymous@$REALM -p $PASSWORD -m WPA-EAP -s eduroam -e TTLS -2 PAP
```

## Notes & Limitations

### EAP-TTLS/PAP

Because FreeRADIUS has no access to a cleartext password when authenticating via PAM, only PAP can be used as an inner/phase two authentication method. This typically means you need to configure clients to use TTLS/PAP (PEAP/MSCHAPv2 will **not** work). This was not originally supported out-the-box by Windows, but Windows 10 now includes a TTLS supplicant. Likewise Android and wpasupplicant on Linux both support TTLS.

### Scalability

Setting up an IMAP connection is slow (~ 2 seconds) and more resource intensive than other authentication methods. This means that the IMAP approach likely does not scale! **pam_imap** does do some caching of credentials which may improve this. Nevertheless you should really only consider this for the smallest of sites.

### GSuite and 2FA

If you're using this with Google GSuite and your account has two-factor authentication turned on, you obviously can't supply the second factor via EAP. This means you won't be able to authenticate on eduroam with your normal GSuite username and password. Fortunately Google have preempted the problem in the form of [app passwords](https://support.google.com/accounts/answer/185833?hl=en), which are designed for legacy applications that don't suppport 2FA. To authenticate on eduroam using a GSuite account that has 2FA turned on, you'll need to [generate a new app password](https://security.google.com/settings/security/apppasswords) and then use your GSuite username and the app password to connect.
