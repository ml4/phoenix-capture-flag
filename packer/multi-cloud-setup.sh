#!/usr/bin/env bash
#
## multi-cloud-setup.sh
#
## script exists because the deployment is to multiple clouds and Azure (as usual) don't do
## stuff expectedly such as ubuntu being the default user in ubuntu images.
## This script in response to `chown: invalid user: ubuntu:ubuntu` etc.

## Check for local user ubuntu
#
if id -u ubuntu >/dev/null 2>&1
then
  echo
  echo "Ubuntu user present"
  echo

  mkdir -m 0700 -p /home/ubuntu/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD mkdir -m 0700 -p /home/ubuntu/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD mkdir -m 0700 -p /home/ubuntu/.ssh OK"
  fi

  mv -f /tmp/id_rsa* /home/ubuntu/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD mv -f /tmp/id_rsa* /home/ubuntu/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD mv -f /tmp/id_rsa* /home/ubuntu/.ssh OK"
  fi

  mkdir -p /home/ubuntu/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD mkdir -p /home/ubuntu/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD mkdir -p /home/ubuntu/.ssh OK"
  fi

  touch /home/ubuntu/.ssh/authorized_keys
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD touch /home/ubuntu/.ssh/authorized_keys FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD touch /home/ubuntu/.ssh/authorized_keys OK"
  fi

  chmod 700 /home/ubuntu/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD chmod 700 /home/ubuntu/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD chmod 700 /home/ubuntu/.ssh OK"
  fi

  chmod 600 /home/ubuntu/.ssh/authorized_keys
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD chmod 600 /home/ubuntu/.ssh/authorized_keys FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD chmod 600 /home/ubuntu/.ssh/authorized_keys OK"
  fi

  cat /tmp/keys/*.pub >> /home/ubuntu/.ssh/authorized_keys
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD cat /tmp/keys/*.pub >> /home/ubuntu/.ssh/authorized_keys FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD cat /tmp/keys/*.pub >> /home/ubuntu/.ssh/authorized_keys OK"
  fi

  chown -R ubuntu:ubuntu /home/ubuntu/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD chown -R ubuntu:ubuntu /home/ubuntu/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD chown -R ubuntu:ubuntu /home/ubuntu/.ssh OK"
  fi
elif id -u azureuser >/dev/null 2>&1
then
  echo
  echo "Azure (user azureuser instead of ubuntu present)"
  echo

  mkdir -m 0700 -p /home/azureuser/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD mkdir -m 0700 -p /home/azureuser/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD mkdir -m 0700 -p /home/azureuser/.ssh OK"
  fi

  mv -f /tmp/id_rsa* /home/azureuser/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD mv -f /tmp/id_rsa* /home/azureuser/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD mv -f /tmp/id_rsa* /home/azureuser/.ssh OK"
  fi

  mkdir -p /home/azureuser/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD mkdir -p /home/azureuser/.ssh  FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD mkdir -p /home/azureuser/.ssh OK"
  fi

  touch /home/azureuser/.ssh/authorized_keys
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD touch /home/azureuser/.ssh/authorized_keys FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD touch /home/azureuser/.ssh/authorized_keys OK"
  fi

  chmod 700 /home/azureuser/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD chmod 700 /home/azureuser/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD chmod 700 /home/azureuser/.ssh OK"
  fi

  chmod 600 /home/azureuser/.ssh/authorized_keys
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD chmod 600 /home/azureuser/.ssh/authorized_keys FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD chmod 600 /home/azureuser/.ssh/authorized_keys OK"
  fi

  cat /tmp/keys/*.pub >> /home/azureuser/.ssh/authorized_keys
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD cat /tmp/keys/*.pub >> /home/azureuser/.ssh/authorized_keys FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD cat /tmp/keys/*.pub >> /home/azureuser/.ssh/authorized_keys OK"
  fi

  chown -R azureuser:azureuser /home/azureuser/.ssh
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    echo "ERROR: CMD chown -R azureuser: /home/azureuser/.ssh FAILED [exit ${rCode}]"
    exit ${rCode}
  else
    echo "INFO: CMD chown -R azureuser: /home/azureuser/.ssh OK"
  fi
fi
