#!/bin/bash

# NOTE: this assumes we are running in Travis or Vagrant,
# so happily installs things globally, and with abandon.

set -eo pipefail

# if running in vagrant, `/vagrant` exists;
# Then, setup local virtualenv and use it.
if [ -d /vagrant ]; then
  (cd ~; virtualenv -p python3 venv)
  source ~/venv/bin/activate
fi

# Install molecule
pip install "molecule[ansible,docker,lint]" testinfra docker

# Install linting tools
pip install yamllint ansible-lint flake8

# Let's Encrypt CA (boulder)
export GOPATH=~/gopath
mkdir -p $GOPATH
git clone https://github.com/letsencrypt/boulder/ $GOPATH/src/github.com/letsencrypt/boulder
cd $GOPATH/src/github.com/letsencrypt/boulder
for f in va.json va-remote-a.json va-remote-b.json; do
    jq '.va.dnsResolvers = ["10.77.77.1:53"]' test/config/$f > test/config/$f.new
    mv test/config/$f.new test/config/$f
done
docker-compose up -d
until curl -s http://127.0.0.1:4001/directory; do sleep 0.5; done
cd -

# nginx for http-01 challenges
mkdir -p /tmp/www/.well-known/acme-challenge
docker run -d -v /tmp/www:/usr/share/nginx/html:ro -p 10.77.77.1:5002:80 nginx

# powerdns for dns-01 challenges
docker build -t pdns -f molecule/Dockerfile.pdns molecule/
docker run -d -p 10.77.77.1:53:53/udp -p 10.77.77.1:53:53 -p 10.77.77.1:8081:8081 pdns

# create example.com dummy zone for http-01
curl -v -H 'X-API-Key: dummy' -X POST http://10.77.77.1:8081/api/v1/servers/localhost/zones \
    -d '{ "name": "le2.wtf.", "kind": "Native", "nameservers": ["localhost."] }'
curl -v -H 'X-API-Key: dummy' -X PATCH http://10.77.77.1:8081/api/v1/servers/localhost/zones/le2.wtf. \
    -d '{"rrsets": [
            {"name": "le2.wtf.", "type": "A", "ttl": 60, "changetype": "REPLACE", "records": [
                {"content": "10.77.77.1", "disabled": false}
            ]}
    ]}'

curl -v -H 'X-API-Key: dummy' -X POST http://10.77.77.1:8081/api/v1/servers/localhost/zones \
    -d '{ "name": "le3.wtf.", "kind": "Native", "nameservers": ["localhost."] }'

echo "Environment setup done!"
