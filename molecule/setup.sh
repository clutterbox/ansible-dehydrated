#!/bin/bash

set -eo pipefail

# Install molecule
pip3 install "molecule>=2.22rc3" docker

# Let's Encrypt CA (boulder)
export GOPATH=~/gopath
mkdir -p $GOPATH
git clone https://github.com/letsencrypt/boulder/ $GOPATH/src/github.com/letsencrypt/boulder
cd $GOPATH/src/github.com/letsencrypt/boulder
jq '.va.dnsResolvers = ["10.77.77.1:53"]' test/config/va.json > test/config/va.json.new
mv test/config/va.json.new test/config/va.json
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
