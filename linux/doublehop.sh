#!/bin/bash
####################################################################################################
##
#   Double hop ssh tunnel to the Azure product-vpn subscription to get around the BS corporate security 
##
#   Author: Kmac
#   Date:   April 1, 2024
##
####################################################################################################

AZURE_LINUX_HOST=10.94.18.8
AZURE_WINDOWS_HOST=10.94.17.4
ONPREM_LINUX_HOST='admin@duc313-100g.eng.qumulo.com'
TUNNEL_PORT=5150

SSHKEY='/home/admin/keys/gnsdemo-azure-ubuntu.pem'

set -x 
ssh -L ${TUNNEL_PORT}:localhost:${TUNNEL_PORT} ${ONPREM_LINUX_HOST} ssh -i ${SSHKEY} -L ${TUNNEL_PORT}:${AZURE_WINDOWS_HOST}:3389  -N qumulo@${AZURE_LINUX_HOST}
set +x 

###
# Then rdp to localhost:TUNNEL_PORT 
###
open rdp://localhost:${TUNNEL_PORT}

