# clutterbox.dehydrated

Install, configure and run dehydrated Let's Encrypt client


## Role Variables

Variable | Function | Default
--- | --- | ---
dehydrated_accept_letsencrypt_terms | Set to yes to automatically register and accept Let's Encrypt terms | no
dehydrated_contactemail | E-Mail address (required) | 
dehydrated_domains | List of domains to request SSL certificates for | 
dehydrated_deploycert | Script to run to deploy a certificate (see below) | 
dehydrated_wellknown | Directory where to deploy http-01 challenges | 
dehydrated_install_root | Where to install dehydrated | /opt/dehydrated
dehydrated_update | Update dehydrated sources on ansible run | yes
dehydrated_version | Which version to check out from github | HEAD
dehydrated_challengetype | Challenge to use (http-01, dns-01) | http-01
dehydrated_use_lexicon | Use lexicon if challengetype is dns-01 | yes
dehydrated_lexicon_dns | Options for running lexicon | {}
dehydrated_key_algo | Keytype to generate (rsa, prime256v1, secp384r1) | rsa
dehydrated_keysize | Size of Key (only for rsa Keys) | 4096
dehydrated_ca | CA to use | https://acme-v02.api.letsencrypt.org/directory
dehydrated_cronjob | Install cronjob for certificate renewals | yes
dehydrated_config_extra | Add arbitrary text to config | 


## Using dns-01 challenges

When dehydrated_challengetype is set to dns-01, this role will automatically install lexicon from python pip to be able to set and remove the necessary DNS-Records needed to obtain an SSL certificate.

lexicon uses environment variables for username and password.

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
    apt_http_dehydrated_accept_letsencrypt_terms: yes
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
    apt_http_dehydrated_accept_letsencrypt_terms: yes
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

Additional hooks can be put in the /etc/dehydrated/hooks.d directory. Every file will be executed as a dehydrated hook. If you deploy additional hooks with ansible, be sure to deploy them before this role is run. The directory must be created manually in this case.

Filenames must match ^[a-zA-Z0-9_-]+$

For Infos on hooks see https://github.com/lukas2511/dehydrated/blob/master/docs/examples/hook.sh

```yaml
- hosts: servers
  tasks:
    - name: Create hooks.d
      file:
        dest: /etc/dehydrated/hooks.d
        state: directory
        owner: root
        group: root
        mode: 0700
    - copy:
        src: myhook
        dest: dehydrated/hooks.d/myhook
        mode: 0755
- hosts: servers
  roles:
    - clutterbox.dehydrated
```

## License

MIT Licsense

## Author Information

Alexander Zielke - mail@alexander.zielke.name
