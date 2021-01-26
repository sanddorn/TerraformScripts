import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_jenkins_service_is_running(host):
    jenkins_service = host.service("jenkins")

    assert jenkins_service.is_enabled
    assert jenkins_service.is_running
