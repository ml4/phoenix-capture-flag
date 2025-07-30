#!/usr/bin/env bash
#
## run.sh base creation
## 2025-07-30::11:26:30 ml4
#
## this script should cater for the necessary complexity required for this repo.
#
###################################################################################################################

readonly SCRIPT_NAME="$(basename ${0})"

##################################################################################################################################################
## log
## pipeline-relevant log output
## Usage: log "ERROR" "${FUNCNAME[0]}" "Wrong number of arguments to log_run"
#
function log {
  red="\033[1;31m"
  green="\033[1;32m"
  yellow="\033[1;33m"
  blue="\033[1;34m"
  purple="\033[1;35m"
  cyan="\033[1;36m"
  white="\033[1;37m"
  reset="\033[0m"

  local -r level="${1}"
  if [ "${level}" == "INFO" ]
  then
    COL=${green}
  elif [ "${level}" == "ERROR" ]
  then
    COL=${red}
  elif [ "${level}" == "WARN" ]
  then
    COL=${yellow}
  fi

  local -r func="${2}"
  local -r message="${3}"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S %Z")
  >&2 echo -e "${cyan}${timestamp}${reset} [${COL}${level}${reset}] [${cyan}${SCRIPT_NAME}${reset}:${yellow}${func}${reset}] ${message}"
}

#####  #    # # #      #####
#    # #    # # #      #    #
#####  #    # # #      #    #
#    # #    # # #      #    #
#    # #    # # #      #    #
#####   ####  # ###### #####

## build
#
function build {
  #####  #    # #    #    #####    ##    ####  #    # ###### #####
  #    # #    # ##   #    #    #  #  #  #    # #   #  #      #    #
  #    # #    # # #  #    #    # #    # #      ####   #####  #    #
  #####  #    # #  # #    #####  ###### #      #  #   #      #####
  #   #  #    # #   ##    #      #    # #    # #   #  #      #   #
  #    #  ####  #    #    #      #    #  ####  #    # ###### #    #

  if [[ -z "$(command -v packer)" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "Install Packer first"
    exit 1
  fi

  if [[ -z "$(command -v terraform)" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "Install Terraform first"
    exit 1
  fi

  if [[ -z "${AWS_DEFAULT_REGION}" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "AWS_DEFAULT_REGION is not set"
    exit 1
  fi

  if [[ -z "${AWS_ACCESS_KEY_ID}" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "AWS_ACCESS_KEY_ID is not set"
    exit 1
  fi

  if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "AWS_SECRET_ACCESS_KEY is not set"
    exit 1
  fi

  ## NOTE: IF READING THROUGH, GO TO PACKER CONFIG AND THEN COME BACK HERE TO CONTINUE
  #
  draw_line cyan
  log "INFO" "${FUNCNAME[0]}" "${cyan}RUNNING PACKER${reset}"
  packer build -var=aws_access_key_id="${AWS_ACCESS_KEY_ID}" \
               -var=aws_secret_access_key="${AWS_SECRET_ACCESS_KEY}" \
               -var=aws_default_region="${AWS_DEFAULT_REGION}" \
               -timestamp-ui \
               .
  rCode=${?}
  if [[ ${rCode} -gt 0 ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "${red}Packer failed.${reset}"
    exit 1
  else
    log "INFO" "${FUNCNAME[0]}" "${green}Packer succeeded.${reset}"
  fi
}

#    #   ##   # #    #
##  ##  #  #  # ##   #
# ## # #    # # # #  #
#    # ###### # #  # #
#    # #    # # #   ##
#    # #    # # #    #

## main
#
function main {
  ## ensure ssh keys in each region
  #
  cat ssh.keys | awk -F, '{print $1}' | while read key_name
  do
    log "INFO" "${FUNCNAME[0]}" "Clearing ssh ${key_name} key in build region ${purple}${AWS_DEFAULT_REGION}${reset}"
    export region=${AWS_DEFAULT_REGION}
    aws ec2 delete-key-pair --region ${region} --key-name ${key_name} >/dev/null 2>&1   # ignore failures mostly associated with key pair absence
    sleep 2 # for the cloud
    log "INFO" "${FUNCNAME[0]}" "Uploading ${key_name} key pair to build region ${purple}${region}${reset}"
    aws ec2 import-key-pair --region ${region} --key-name ${key_name} --public-key-material "$(grep ${key_name} ssh.keys | awk '{print $NF}')"
    rCode=${?}
    if [[ ${rCode} -gt 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Failed: aws ec2 import-key-pair --region ${region} --key-name ${key_name} --public-key-material $(grep ${key_name} ssh.keys | awk '{print $NF}')"
      exit ${rCode}
    fi
  done

  ## packer build will use ssh keys in each region for build testing
  #
  log "INFO" "${FUNCNAME[0]}" "packer init -upgrade base.pkr.hcl"
  packer init -upgrade base.pkr.hcl
  rCode=${?}
  if [[ ${rCode} -gt 0 ]]
  then
    log "WARN" "${FUNCNAME[0]}" "Failed: packer init -upgrade base.pkr.hcl"
  fi

  build

  log "INFO" "${FUNCNAME[0]}" "All done"
}

main "$@"
#
## jah brendan
