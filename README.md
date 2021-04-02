[![Build Status](https://travis-ci.com/clutterbox/ansible-dehydrated.svg?branch=master)](https://travis-ci.com/clutterbox/ansible-dehydrated)

# clutterbox.dehydrated

Install, configure and run dehydrated Let's Encrypt client

- [clutterbox.dehydrated](#clutterboxdehydrated)
  * [Role Variables](#role-variables)
  * [Using dns-01 challenges](#using-dns-01-challenges)
  * [using systemd timers](#using-systemd-timers)
  * [Overriding per certificate config](#overriding-per-certificate-config)
  * [dehydrated_deploycert](#dehydrated-deploycert)
    + [Variables](#variables)
  * [Example Playbooks](#example-playbooks)
    + [Using http-01 .well-known/acme-challenge](#using-http-01-well-known-acme-challenge)
    + [Using dns-01 with cloudflare](#using-dns-01-with-cloudflare)
    + [Using dehydrated_deploycert with multiple certificates](#using-dehydrated-deploycert-with-multiple-certificates)
  * [Additinal hook scripts](#additinal-hook-scripts)
    + [Writing shell fragments for single hooks](#writing-shell-fragments-for-single-hooks)
    + [deploying complete hook script files](#deploying-complete-hook-script-files)
  * [Testing](#testing)
  * [License](#license)
  * [Author Information](#author-information)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>



## Role Variables

Variable | Function | Default
--- | --- | ---
dehydrated_accept_letsencrypt_terms | Set to yes to automatically register and accept Let's Encrypt terms | no
dehydrated_contactemail | E-Mail address (required) |
dehydrated_account_key | If set, deploy this file containing pre-registered private key |
dehydrated_domains | Content that will be written to domains.txt for obtaining certificates. See: https://github.com/dehydrated-io/dehydrated/blob/master/docs/domains_txt.md |
dehydrated_deploycert | Script to run to deploy a certificate (see below) |
dehydrated_wellknown | Directory where to deploy http-01 challenges |
dehydrated_install_root | Where to install dehydrated | /opt/dehydrated
dehydrated_update | Update dehydrated sources on ansible run | yes
dehydrated_version | Which version to check out from github | HEAD
dehydrated_challengetype | Challenge to use (http-01, dns-01) | http-01
dehydrated_use_lexicon | Enable the use of lexicon | yes if dehydrated_challengetype == dns-01 else no
dehydrated_lexicon_dns | Options for running lexicon | {}
dehydrated_hooks | Dict with hook-names for which to add scripts |
dehydrated_hook_scripts | Add additional scripts to hooks-Directory | []
dehydrated_key_algo | Keytype to generate (rsa, prime256v1, secp384r1) | rsa
dehydrated_keysize | Size of Key (only for rsa Keys) | 4096
dehydrated_ca | CA to use | https://acme-v02.api.letsencrypt.org/directory
dehydrated_cronjob | Install cronjob for certificate renewals | yes
dehydrated_systemd_timer | Use systemd timer for certificate renewals | no
dehydrated_config_extra | Add arbitrary text to config |
dehydrated_run_on_changes | If dehydrated should run if the list of domains changed | yes
dehydrated_systemd_timer_onfailure | If set, an OnFailure-Directive will be added to the systemd unit |
dehydrated_cert_config | Override configuration for certificates | []
dehydrated_repo_url | Specify URL to git repository of dehydrated | https://github.com/dehydrated-io/dehydrated.git
dehydrated_install_pip | Whether pip will be installed when using lexicon | yes
dehydrated_pip_package | Name of pip package | python3-pip if ansible is running on python3, otherwise python-pip
dehydrated_pip_executable | Name of pip executable to use | autodetected by pip module

## Account registration

The first time this role is used, and when `dehydrated_accept_letsencrypt_terms` is true, register with Let's Encrypt, using the value of `dehydrated_contactemail` (required).   Your account details, and private key, will be created by `dehydrated` and stored in `/etc/dehydrated/accounts/<HASH>` on the target system.

Alternatively, if you've already setup `dehydrated` once and want to use the same account for all installations, copy your Lets' Encrypt private key (`account_key.pem`) into your ansible configuration, and set `dehydrated_account_key` to the name that file.  Subsequent installations will use that key instead of registering a **new** account.

**IMPORTANT** The `account_key.pem` is a private key with no passphrase.  When you copy it into your Ansible configuration, make sure to use `ansible-vault` or similar to encrypt the contents of that file, at rest.  If you use `ansible-vault` to encrypt it, `ansible` will automatically decrypt when referenced and installed on the target system.

## Using dns-01 challenges

When `dehydrated_challengetype` is set to `dns-01`, this role will automatically install `lexicon` from python pip to be able to set and remove the necessary DNS records needed to obtain an SSL certificate.

`lexicon` uses environment variables for username/token and password/secret; see examples below.

### Platforms supporting `dns-01` challenges

All platforms supported by this role will work with `dns-01` challenges wherever the latest version of `lexicon` can be installed.  `lexicon` is pretty aggressive about deprecating older versions of Python, and it (indirectly) relies upon the `cryptography` package which is similarly aggressive.  For those who need this on older distributions, it may be possible to find specific older versions of `lexicon` and `cryptography` to install that will work on the following distributions:

  - Debian 8 (Jessie)
  - Ubuntu 16.04 (Xenial)

## using systemd timers

It is possible to use a systemd-timer instead of a cronjob to renew certificates.

**Note**: Enabling the systemd timer does *not* disable the cronjob. This might change in the future.

```yaml
dehydrated_systemd_timer: yes
dehydrated_cronjob: no
```

## Overriding per certificate config

The Configration for single certificates can be overridden using `dehydrated_cert_config`.

`dehydrated_cert_config` must be a list of dicts. Only the elemenent `name:` is mandatory ans must match a certificate name. The certificate name is either the first domain listed in domains.txt or the certificate alias, if defined.

Format is as follows:

```yaml
dehydrated_cert_config:
 - name: # certificate name or alias (mandatory)
   state: present # present or absent (optional)
   challengetype: # override CHALLENGE (optional)
   wellknown: # override WELLKNOWN (optional)
   key_algo: # override KEY_ALGO (optional)
   keysize: # override KEYSIZE (optional)
```

## dehydrated_deploycert

The variable dehydrated_deploycert contains a shellscript fragment to be executed when a certificate has successfully been optained. This variable can either be a multiline string or a hash of multiline strings.

```yaml
dehydrated_deploycert: |
  service nginx reload
```

In this example, for ever certificate obtained, nginx will be reloaded

```yaml
dehydrated_deploycert:
  example.com: |
    service nginx reload
  service.example.com: |
    cat ${FULLCHAINFILE} ${KEYFILE} > /etc/somewhere/ssl/full.pem
    service someservice reload
```

Here, for certificates with the primary domain example.com, nginx will be reloaded and for service.example.com the certificate, intermediate and key will be written to another file and someservice is reloaded.

### Variables

Variable | Function
--- | ---
DOMAIN | (Primary) Domain of the certificate
KEYFILE | Full path to the keyfile
CERTFILE | Full path to certificate file
FULLCHAINFILE | Full path to file containing both certificate and intermediate
CHAINFILE | Full path to intermediate certificate file
TIMESTAMP | Timestamp when the  certificate was created.

## Example Playbooks

### Using http-01 .well-known/acme-challenge

```yaml
- hosts: servers
  vars:
    dehydrated_accept_letsencrypt_terms: yes
    dehydrated_contactemail: hostmaster@example.com
    dehydrated_wellknown: /var/www/example.com/.well-known/acme-challenge
    dehydrated_domains: |
      example.com
    dehydrated_deploycert: |
      service nginx reload
  roles:
    - clutterbox.dehydrated
```

### Using dns-01 with cloudflare
```yaml
- hosts: servers
  vars:
    dehydrated_accept_letsencrypt_terms: yes
    dehydrated_contactemail: hostmaster@example.com
    dehydrated_challengetype: dns-01
    dehydrated_lexicon_dns:
      LEXICON_CLOUDFLARE_USERNAME: hostmaster@example.com
      LEXICON_CLOUDFLARE_TOKEN: f7e7e...
    dehydrated_domains: |
      example.com
    dehydrated_deploycert: |
      service nginx reload
  roles:
    - clutterbox.dehydrated
```

### Using dehydrated_deploycert with multiple certificates
```yaml
- hosts: servers
  vars:
    # [...]
    dehydrated_domains: |
      example.com www.example.com
      sub.example.com
      service.example.com
    dehydrated_deploycert:
      example.com: |
        service nginx reload
      sub.example.com
        cat ${FULLCHAINFILE} ${KEYFILE} > /etc/somewhere/ssl/full.pem
        service someservice reload
      service.example.com:
        rsync -rl $(dirname ${KEYFILE})/ deploy@192.0.2.1:/etc/ssl/${DOMAIN}/
        ssh deploy@192.0.2.1 sudo service someservice reload
  roles:
    - clutterbox.dehydrated
```

## Additinal hook scripts

This role offers two different ways to deploy additional hooks:
 * Using shell fragments
 * by deploying complete hook scripts

For Information on how to use these hooks see https://github.com/lukas2511/dehydrated/blob/master/docs/examples/hook.sh

This role follows the example hook script as close as possible.

### Writing shell fragments for single hooks

Single hooks can be written using the `dehydrated_hooks` variable. The variable is a dict where the key is the name of a hook and the value is the shell fragment.

```yaml
dehydrated_hooks:
  exit_hook: |
    echo "simple cleanup"
  deploy_ocsp: |
    cp "${OCSPFILE}" /etc/nginx/ssl/
    nginx -s reload
```

For every known hook, well-know variables are set according to the example hook script (see link above).

### deploying complete hook script files

Additional hooks can be deployed using `dehydrated_hook_scripts` or can be put in the /etc/dehydrated/hooks.d directory manually.

The syntax for `dehydrated_hook_scripts` is as follows:

```yaml
dehydrated_hook_scripts:
  - src: # source filename
    name: # optional filename inside hooks.d. defaults to filename in src
    state: # state present or absent. defaults to present
```

If you have a hook-script called myhook in your playbook-directory, it can be deployed like:
```yaml
dehydrated_hook_scripts:
  - src: "{{ playbook_dir }}/myhook"
```

If you decide, that you don't need the hook anymore, you can add `state: absent` and it will be deleted.

**Note:** Filenames must match ^[a-zA-Z0-9_-]+$ - otherwise they won't be executed!

# Testing

This role is automatically tested using Travis CI. Local testing can be done using Vagrant.  Both local (Vagrant) and Travis utilize the `molecule/setup.sh` script to setup the testing environment.

Multiple services are started in the environment to test both http-01 and dns-01.

Service | Usage
---|---
boulder (using docker) | Let's Encrypt CA for validations
nginx | webserver for http-01
powerdns | Used as a nameserver for dns-01. lexicon as a plugin to manipulate records.

## Local Vagrant testing example

Assuming you have Vagrant already configured, run a complete test via:

    vagrant up
    vagrant ssh
    source ~/venv/bin/activate
    cd /vagrant
    molecule test
    exit
    vagrant destroy

# License

MIT License

# Author Information

Alexander Zielke - mail@alexander.zielke.name
