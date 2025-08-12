#!/usr/bin/env bash
#
## run.sh base creation
## 2025-07-30::11:26:30 ml4
#
## this script should cater for the necessary complexity required for this repo.
#
##################################################################################################################################################

##################################################################################################################################################
## setup
#
function setup_environment_for_cloud_build {
  if [[ -z "$(command -v packer)" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "Install Packer first"
  fi

  if [[ -z "$(command -v terraform)" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "Install Terraform first"
  fi

  ## AWS creds from the manual run of the instruqt ephemeral no-default-vpc CSP account setup
  #
  if [[ -z "${AWS_DEFAULT_REGION}" ]]
  then
    read -p "Enter AWS_DEFAULT_REGION: " aws_default_region
    export AWS_DEFAULT_REGION=${aws_default_region}
  fi

  if [[ -z "${AWS_ACCESS_KEY_ID}" ]]
  then
    read -p "Enter AWS_ACCESS_KEY_ID: " aws_access_key_id
    export AWS_ACCESS_KEY_ID=${aws_access_key_id}
  fi

  if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]
  then
    read -sp "Enter AWS_SECRET_ACCESS_KEY: " aws_secret_access_key
    export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
  fi

  if [[ -z "${AWS_BASE_IMAGE_AMI}" ]]
  then
    echo
    echo "Getting Ubuntu ami ID"
    aws_u22_marketplace_id=$(aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate)[-1].ImageId" --output text)
    read -p "Enter AWS_BASE_IMAGE_AMI (${aws_u22_marketplace_id}): " aws_base_image_ami
    if [[ -z "${aws_base_image_ami}" ]]
    then
      export aws_base_image_ami=${aws_u22_marketplace_id}
    fi
    export AWS_BASE_IMAGE_AMI=${aws_base_image_ami}
  fi

  ## Azure creds from the manual run of the instruqt ephemeral no-default-vpc CSP account setup
  #
  if [[ -z "${ARM_TENANT_ID}" ]]
  then
    read -p "Enter ARM_TENANT_ID: " arm_tenant_id
    export ARM_TENANT_ID=${arm_tenant_id}
  fi

  if [[ -z "${ARM_SUBSCRIPTION_ID}" ]]
  then
    read -p "Enter ARM_SUBSCRIPTION_ID: " arm_subscription_id
    export ARM_SUBSCRIPTION_ID=${arm_subscription_id}
  fi

  if [[ -z "${ARM_CLIENT_ID}" ]]
  then
    read -p "Enter ARM_CLIENT_ID (Service Principal ID): " arm_client_id
    export ARM_CLIENT_ID=${arm_client_id}
  fi

  if [[ -z "${ARM_CLIENT_SECRET}" ]]
  then
    read -sp "Enter ARM_CLIENT_SECRET (Service Principal Passwd): " arm_client_secret
    export ARM_CLIENT_SECRET=${arm_client_secret}
  fi

  ## any staff member might run this code, and they are the owner of the build SSH key. Others will need to be passed in order for everyone to be able to login
  ## BUILD_SSH_KEY is the name of the key as iot will show in the cloud i.e. 'ml4' or 'ralphmr' not 'ml4.pub' etc.
  #
  if [[ -z "${BUILD_SSH_KEY}" ]]
  then
    echo
    read -p "Enter BUILD_SSH_KEY (filename of SSH private key name in ~/.ssh to use for build): " build_ssh_key
    export BUILD_SSH_KEY=${build_ssh_key}
  fi

  echo
  #
  ## done

  ## check user wants to run the terraform part (or did they break the packer build and wanna retest just that bit == skip)
  #
  RERUN=run
  log "WARN" "${FUNCNAME[0]}" "Proceed with Terraform non-default VPC/VNet deployment or skip to Packer build?"
  read -p "Enter to run Terraform, enter lower case 's' to skip or ^C to exit: " RERUN

  if [[ -z "${RERUN}" ]]
  then
    ## terraform deploy of non-default VPC for packer build VM
    #
    if [[ -d .terraform || -r .terraform.lock.hcl || -r terraform.tfstate ]]
    then
      log "WARN" "${FUNCNAME[0]}" "Terraform objects in this directory exist already."
      read -p "Enter ^C to exit to handle manually or return to continue with existing state files. " continue_selected
    fi
    #
    ## ok we either left or are continuing
    #
    log "INFO" "${FUNCNAME[0]}" "Running terraform init -upgrade"
    terraform init -upgrade
    rCode=${?}
    if [[ ${rCode} > 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return status ${rCode} for command terraform init -upgrade"
      popd >/dev/null
      rm -rf ${tmpdir}
    fi

    log "INFO" "${FUNCNAME[0]}" "Running terraform plan -detailed-exitcode"
    terraform plan -detailed-exitcode
    rCode=${?}
    if [[ ${rCode} == 0 ]]
    then
      log "WARN" "${FUNCNAME[0]}" "Terraform plan succeeded with empty diff (no changes)"
    elif [[ ${rCode} == 1 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Terraform plan errored"
    fi

    log "INFO" "${FUNCNAME[0]}" "Running terraform apply -auto-approve"
    terraform apply -auto-approve
    rCode=${?}
    if [[ ${rCode} > 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform apply -auto-approve > 0"
    fi
    #
    ## at this point, we have a non-default VPC deployed in an ephemeral AWS VPC and the equivalent VNet in an ephemeral Azure subscription

  else
    log "INFO" "${FUNCNAME[0]}" "OK skipping Terraform deploy, going straight to Packer tasks"

  fi

  ## setup for Packer run
  #
  if [[ -z "${AWS_BUILD_SUBNET}" ]]
  then
    export AWS_BUILD_SUBNET=$(terraform output | grep ^subnet_id | awk '{print $NF}' | tr -d \")
    if [[ -z "${AWS_BUILD_SUBNET}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform output | grep ^subnet_id | awk '{print $NF}' | tr -d \" > 0"
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "AWS_BUILD_SUBNET: ${AWS_BUILD_SUBNET}"
  fi

  if [[ -z "${AWS_BUILD_VPC}" ]]
  then
    export AWS_BUILD_VPC=$(terraform output | grep ^vpc_id | awk '{print $NF}' | tr -d \")
    if [[ -z "${AWS_BUILD_VPC}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform output | grep ^vpc_id | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "AWS_BUILD_VPC: ${AWS_BUILD_VPC}"
  fi

  if [[ -z "${ARM_BUILD_RG}" ]]
  then
    export ARM_BUILD_RG=$(terraform output | grep ^azure_resource_group_name | awk '{print $NF}' | tr -d \")
    if [[ -z "${ARM_BUILD_RG}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform output | grep ^azure_resource_group_name | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "ARM_BUILD_RG: ${ARM_BUILD_RG}"
  fi

  if [[ -z "${ARM_BUILD_VNET}" ]]
  then
    export ARM_BUILD_VNET=$(terraform output | grep ^azure_vnet_name | awk '{print $NF}' | tr -d \")
    if [[ -z "${ARM_BUILD_VNET}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform output | grep ^azure_vnet_name | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "ARM_BUILD_VNET: ${ARM_BUILD_VNET}"
  fi

  if [[ -z "${ARM_BUILD_SUBNET}" ]]
  then
    export ARM_BUILD_SUBNET=$(terraform output | grep ^azure_subnet_id | awk '{print $NF}' | tr -d \")
    if [[ -z "${ARM_BUILD_SUBNET}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform output | grep ^azure_subnet_id | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "ARM_BUILD_SUBNET: ${ARM_BUILD_SUBNET}"
  fi

  ## send SSH public keys to AWS. Public keys are called <github handle>.pub
  #
  for key_file in `/bin/ls -1 keys/*.pub`
  do
    key_name=$(echo ${key_file} | sed 's/keys\///' | sed 's/\.pub//')
    log "INFO" "${FUNCNAME[0]}" "Clearing ssh ${key_name} key in build region ${purple}${AWS_DEFAULT_REGION}${reset}"
    aws ec2 delete-key-pair --region ${region} --key-name ${key_name} >/dev/null 2>&1   # ignore failures mostly associated with key pair absence
    sleep 2 # for the cloud
    log "INFO" "${FUNCNAME[0]}" "Uploading ${key_name} key pair to build region ${purple}${region}${reset}"
    aws ec2 import-key-pair --region ${region} --key-name ${key_name} --public-key-material fileb://keys/${key_name}.pub
    rCode=${?}
    if [[ ${rCode} -gt 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Failed: aws ec2 import-key-pair --region ${region} --key-name ${key_name} --public-key-material fileb://keys/${key_name}.pub"
    fi
  done
  #
  ## NOT done atm for Azure - not needed?
}

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
  >&2 echo -e "${cyan}${timestamp}${reset} [${COL}${level}${reset}] [${cyan}run.sh${reset}:${yellow}${func}${reset}] ${message}"
}

#####  #    # # #      #####
#    # #    # # #      #    #
#####  #    # # #      #    #
#    # #    # # #      #    #
#    # #    # # #      #    #
#####   ####  # ###### #####

##################################################################################################################################################
## build
#
function build_cloud_images {
  #####  #    # #    #    #####    ##    ####  #    # ###### #####
  #    # #    # ##   #    #    #  #  #  #    # #   #  #      #    #
  #    # #    # # #  #    #    # #    # #      ####   #####  #    #
  #####  #    # #  # #    #####  ###### #      #  #   #      #####
  #   #  #    # #   ##    #      #    # #    # #   #  #      #   #
  #    #  ####  #    #    #      #    #  ####  #    # ###### #    #

  ## NOTE: IF READING THROUGH, GO TO PACKER CONFIG AND THEN COME BACK HERE TO CONTINUE
  #
  pushd packer &>/dev/null
  log "INFO" "${FUNCNAME[0]}" "${cyan}RUNNING PACKER IN ${PWD}${reset}"
  if [[ ! -r "phoenix-capture-flag.pkr.hcl" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "No Packer manifest created. Bye."
  fi
  packer init -upgrade . && \
  packer build -var=aws_access_key_id="${AWS_ACCESS_KEY_ID}" \
               -var=aws_secret_access_key="${AWS_SECRET_ACCESS_KEY}" \
               -var=aws_default_region="${AWS_DEFAULT_REGION}" \
               -var=ami="${AWS_BASE_IMAGE_AMI}" \
               -var=subnet_id="${AWS_BUILD_SUBNET}" \
               -var=vpc_id="${AWS_BUILD_VPC}" \
               -var=build_ssh_key="${BUILD_SSH_KEY}" \
               -var=azure_resource_group="${ARM_BUILD_RG}" \
               -var=azure_vnet="${ARM_BUILD_VNET}" \
               -var=azure_subnet="${ARM_BUILD_SUBNET}" \
               -var=arm_client_id="${ARM_CLIENT_ID}" \
               -var=arm_client_secret="${ARM_CLIENT_SECRET}" \
               -var=arm_subscription_id="${ARM_SUBSCRIPTION_ID}" \
               -var=arm_tenant_id="${ARM_TENANT_ID}" \
               -timestamp-ui \
               .
  rCode=${?}
  if [[ ${rCode} -gt 0 ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "${red}Packer failed.${reset}"
  else
    log "INFO" "${FUNCNAME[0]}" "${green}Packer succeeded.${reset}"
  fi
  popd &>/dev/null
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
  export region=${AWS_DEFAULT_REGION}
  setup_environment_for_cloud_build

  ## solicit username and update the paths in the packer build file
  #
  this_user=$(id -p | head -1 | awk '{print $NF}')
  pushd packer &>/dev/null
  log  "INFO" "${FUNCNAME[0]}" "sed \"s/%%USERNAME%%/${this_user}/g\" phoenix-capture-flag.pkr.hcl.tmpl > phoenix-capture-flag.pkr.hcl"
  sed "s/%%USERNAME%%/${this_user}/g" phoenix-capture-flag.pkr.hcl.tmpl > phoenix-capture-flag.pkr.hcl
  if [[ ! -f "phoenix-capture-flag.pkr.hcl" ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "Packer manifest has not been generated. Bye."
  fi
  popd &>/dev/null

  build_cloud_images #&& rm -f packer/phoenix-capture-flag.pkr.hcl
  log "INFO" "${FUNCNAME[0]}" "Finished"
  unset AWS_BUILD_VPC AWS_BUILD_SUBNET ARM_BUILD_VNET ARM_BUILD_SUBNET
}

main "$@"
#
## jah brendan
