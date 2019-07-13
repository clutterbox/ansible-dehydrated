import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_certificate_file_exists(host):
    f = host.file('/etc/dehydrated/certs/example.com/cert.pem')

    assert f.exists
