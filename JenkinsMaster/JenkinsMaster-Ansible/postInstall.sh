#!/bin/bash
GUEST_IP_ADDRESS=$1
ssh-keygen -R $GUEST_IP_ADDRESS || true
ssh-keyscan -t rsa -H $GUEST_IP_ADDRESS >> ~/.ssh/known_hosts || true
#sshpass -p 'vagrant' ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub vagrant@$GUEST_IP_ADDRESS

