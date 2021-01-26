# Jenkins Server Installation
Dieses Playbook installiert einen jenkins-server. 
Die Installation und das Seed der Jobs ist relativ hart auf die Bedürfnisse eines Ops-Jenkins zum Deployment von Kubernetes-Artefakten zugeschnitten.

## Usage

### Konfiguration
Unter `/inventory` muss für das Inventory für die Installation angepasst werden. 
Als Beispiel kann die "master-only" Konfiguration in `/inventory/vagrant` genutzt werden.

### Installation
`ansible-playbook setup-jenkins.yml -i inventory/${DEPLOY_INVENTORY} -u ${ANSIBLE_USER}`

## Test
Es liegt eine Vagrant-Konfiguration `Vagrantfile` vor, mit der die Installation lokal getestet werden kann.
```shell
$ vagrant destroy -f && vagrant up && ansible-playbook setup-jenkins.yml -i inventory/vagrant -u vagrant
```
