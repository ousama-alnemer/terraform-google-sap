#!/bin/bash

curl -s https://storage.googleapis.com/sapdeploy/dm-templates/sap_hana/startup.sh >> startup.sh
chmod +x startup.sh
source startup.sh

# Verifying HANA deployment
#df -h

#su - [SID]adm

#HDB info
