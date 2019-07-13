import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_certificate_file_exists(host):
    cert = host.file('/etc/dehydrated/certs/example.com/cert.pem')
    chain = host.file('/etc/dehydrated/certs/example.com/chain.pem')
    fullchain = host.file('/etc/dehydrated/certs/example.com/fullchain.pem')
    privkey = host.file('/etc/dehydrated/certs/example.com/privkey.pem')

    assert cert.exists
    assert chain.exists
    assert fullchain.exists
    assert privkey.exists
