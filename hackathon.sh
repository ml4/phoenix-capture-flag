#!/usr/bin/env bash
#
## hackathon.sh capture the flag
## 2025-07-30::11:26:30 ml4
#
## this script should cater for the necessary complexity required for this repo.
#
##################################################################################################################################################

## colors for appropriate output
#
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"
purple="\033[1;35m"
cyan="\033[1;36m"
white="\033[1;37m"
reset="\033[0m"

##################################################################################################################################################
## usage
#
function usage {
  echo -e "${cyan}usage:${reset}"
  echo -e "${cyan}hackathon.sh [prep|run|down]${reset}"
  exit 1
}

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
    pushd on-the-day >/dev/null
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
    popd >/dev/null
  else
    log "INFO" "${FUNCNAME[0]}" "OK skipping Terraform deploy, going straight to Packer tasks"
  fi

  ## setup for Packer run
  #
  if [[ -z "${AWS_BUILD_SUBNET}" ]]
  then
    export AWS_BUILD_SUBNET=$(terraform -chdir=on-the-day output | grep ^subnet_id | awk '{print $NF}' | tr -d \")
    if [[ -z "${AWS_BUILD_SUBNET}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform -chdir=on-the-day output | grep ^subnet_id | awk '{print $NF}' | tr -d \" > 0"
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "AWS_BUILD_SUBNET: ${AWS_BUILD_SUBNET}"
  fi

  if [[ -z "${AWS_BUILD_VPC}" ]]
  then
    export AWS_BUILD_VPC=$(terraform -chdir=on-the-day output | grep ^vpc_id | awk '{print $NF}' | tr -d \")
    if [[ -z "${AWS_BUILD_VPC}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform -chdir=on-the-day output | grep ^vpc_id | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "AWS_BUILD_VPC: ${AWS_BUILD_VPC}"
  fi

  if [[ -z "${ARM_BUILD_RG}" ]]
  then
    export ARM_BUILD_RG=$(terraform -chdir=on-the-day output | grep ^azure_resource_group_name | awk '{print $NF}' | tr -d \")
    if [[ -z "${ARM_BUILD_RG}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform -chdir=on-the-day output | grep ^azure_resource_group_name | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "ARM_BUILD_RG: ${ARM_BUILD_RG}"
  fi

  if [[ -z "${ARM_BUILD_VNET}" ]]
  then
    export ARM_BUILD_VNET=$(terraform -chdir=on-the-day output | grep ^azure_vnet_name | awk '{print $NF}' | tr -d \")
    if [[ -z "${ARM_BUILD_VNET}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform -chdir=on-the-day output | grep ^azure_vnet_name | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "ARM_BUILD_VNET: ${ARM_BUILD_VNET}"
  fi

  if [[ -z "${ARM_BUILD_SUBNET}" ]]
  then
    export ARM_BUILD_SUBNET=$(terraform -chdir=on-the-day output | grep ^azure_subnet_id | awk '{print $NF}' | tr -d \")
    if [[ -z "${ARM_BUILD_SUBNET}" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Return code [${rCode}] from terraform -chdir=on-the-day output | grep ^azure_subnet_id | awk '{print $NF}' | tr -d \""
    fi
  else
      log "INFO" "${FUNCNAME[0]}" "ARM_BUILD_SUBNET: ${ARM_BUILD_SUBNET}"
  fi

  ## send SSH public keys to AWS. Public keys are called <github handle>.pub
  #
  log "INFO" "${FUNCNAME[0]}" "Logging into Azure"
  az login --service-principal --username ${ARM_CLIENT_ID} --password ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} >/dev/null
  rCode=${?}
  if [[ ${rCode} > 0 ]]
  then
    log "INFO" "${FUNCNAME[0]}" "Logging into Azure FAILED:"
    az login --service-principal --username ${ARM_CLIENT_ID} --password ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID} >/dev/null
    read -p "Pausing in case you want to exit here. Enter to continue" NULL
  else
    az account set --subscription "${ARM_SUBSCRIPTION_ID}"
    rCode=${?}
    if [[ ${rCode} > 0 ]]
    then
      log "INFO" "${FUNCNAME[0]}" "Setting Azure subscription FAILED:"
      az account set --subscription "${ARM_SUBSCRIPTION_ID}"
      read -p "Pausing in case you want to exit here. Enter to continue" NULL
    fi
  fi
  #
  ## assuming logging into Azure for script use OK

  for key_file in `/bin/ls -1 keys/*.pub`
  do
    key_name=$(echo ${key_file} | sed 's/keys\///' | sed 's/\.pub//')
    log "INFO" "${FUNCNAME[0]}" "AWS: Clearing ssh ${key_name} key in build region ${purple}${AWS_DEFAULT_REGION}${reset}"
    aws ec2 delete-key-pair --region ${region} --key-name ${key_name} >/dev/null 2>&1   # ignore failures mostly associated with key pair absence
    sleep 2 # for the cloud
    log "INFO" "${FUNCNAME[0]}" "AWS: Uploading ${key_name} key pair to build region ${purple}${region}${reset}"
    aws ec2 import-key-pair --region ${region} --key-name ${key_name} --public-key-material fileb://keys/${key_name}.pub
    rCode=${?}
    if [[ ${rCode} -gt 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Failed: aws ec2 import-key-pair --region ${region} --key-name ${key_name} --public-key-material fileb://keys/${key_name}.pub"
    fi

    log "INFO" "${FUNCNAME[0]}" "Azure: Clearing ssh ${key_name} key in build region ${purple}uksouth${reset}"
    az sshkey delete --name ${key_name} --resource-group phoenix-ctf-rg --yes
    log "INFO" "${FUNCNAME[0]}" "Azure: Uploading ${key_name} key pair to build region ${purple}${region}${reset}"
    az sshkey create --name ${key_name} --resource-group phoenix-ctf-rg --location uksouth --public-key "@keys/${key_name}.pub"
    rCode=${?}
    if [[ ${rCode} -gt 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Failed: az sshkey create --name ${key_name} --resource-group phoenix-ctf-rg --location uksouth --public-key \"@keys/${key_name}.pub\""
    fi
  done
  #
  ## NOT done atm for Azure - not needed?
}

##################################################################################################################################################
## run_tf
#
function run_tf {
  terraform init
  rCode=${?}
  if [[ ${rCode} != 0 ]]
  then
    log "ERROR" "${FUNCNAME[0]}" "${red}terraform init failed${reset}"
    exit ${rCode}
  else
    log "INFO" "${FUNCNAME[0]}" "${green}Running terraform apply in |${PWD}|${reset}"
    terraform apply -auto-approve
    rCode=${?}
    if [[ ${rCode} != 0 ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "${red}terraform apply failed${reset}"
      exit ${rCode}
    fi
  fi
}

##################################################################################################################################################
## log
## pipeline-relevant log output
## Usage: log "ERROR" "${FUNCNAME[0]}" "Wrong number of arguments to log_run"
#
function log {
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
  packer build -force \
               -var=aws_access_key_id="${AWS_ACCESS_KEY_ID}" \
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
  ## accept cli args to guide functions
  #
  arg=${1}
  if [[ -z ${arg} ]]
  then
    usage
  fi

  if [[ "${arg}" == "prep" ]]
  then
    ## Set up the hackathon elements which are required outside of the instruqt environment such as GitHub and HCPT elements.
    ## Do this before the hackathon day.
    #
    ## First, in order to work with HCPT, the user needs a valid HCPT token
    #
    if [[ ! -r ${HOME}/.terraform.d/credentials.tfrc.json ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "${yellow}Ensure you have done a terraform login before continuing.${reset}"
      terraform login
    fi
    hcp_token=$(jq -r '.credentials["app.terraform.io"].token' ${HOME}/.terraform.d/credentials.tfrc.json)

    ## Test the token by hitting the HCP API
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer ${hcp_token}" \
      https://app.terraform.io/api/v2/organizations)

    if [[ "${response_code}" -eq 200 ]]
    then
      log "INFO" "${FUNCNAME[0]}" "${green}Found valid HCP token${reset}"
    else
      log "ERROR" "${FUNCNAME[0]}" "${green}Invalid or expired HCP token. Please fix this or run terraform login and retry${reset}"
      exit 1
    fi

    ## Attempt to detect GITHUB_TOKEN or prompt - needed for oauth setup so that PMR mod publication is possible
    #
    gh_token=
    if [[ -s "${GITHUB_TOKEN}" ]]
    then
      log "INFO" "${FUNCNAME[0]}" "${cyan}GITHUB_TOKEN already instantiated. Reuse for HCPT PMR/GitHub oauth?${reset}"
    fi

    while [[ -z "${gh_token}" ]]
    do
      log "INFO" "${FUNCNAME[0]}" "${green}Finding GitHub PAT${reset}"
      read -sp "Enter GitHub PAT [${GITHUB_TOKEN:0:10}*****]> " gh_token
      if [[ -z "${gh_token}" ]]
      then
        gh_token=${GITHUB_TOKEN}
      fi
      echo
      log "INFO" "${FUNCNAME[0]}" "${green}Using ${GITHUB_TOKEN:0:10}*****${reset}"
    done

    ## prompt for email to configure TFE organizations
    #
    # while true
    # do
    #   read -p "Enter the email needed to create HCPT organizations> " email
    #   if [[ "${email}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
    #   then
    #     break
    #   else
    #     echo "Invalid email format, please try again."
    #   fi
    # done

    ## ask for which teams
    #
    # declare -A teams
    teams=()
    log "INFO" "${FUNCNAME[0]}" "${green}Getting GitHub/HCPT organization names for each customer team${reset}"
    while true
    do
      read -p "Enter each customer GitHub/HCPT org name (blank line to finish)> " team_name
      if [[ -z ${team_name} ]]
      then
        break
      fi
      team_name=$(echo ${team_name} | sed 's/ //g')
      org_test=$(curl -s https://api.github.com/orgs/${team_name} | jq -r '.login')
      if [[ ${org_test} == "null" ]]
      then
        log "ERROR" "${FUNCNAME[0]}" "${red}GitHub has no such organization. ${reset}"
        exit 1
      fi

      # echo "Select CSP for team ${team_name}:"
      # select provider in AWS Azure GCP
      # do
      #   case ${provider} in
      #     AWS|Azure|GCP)
      #       teams[${team_name}]=${provider}
      #       break
      #       ;;
      #     *)
      #       echo "Invalid selection"
      #       exit 1
      #       ;;
      #   esac
      # done

      teams+=("${team_name}")
    done

    ## Iterate the teams creating directories, adding terraform code and running terraform in the respective directories (GitHub provider instances per team).
    #
    # for team in ${!teams[@]}
    for team in "${teams[@]}"
    do
      if [[ -d ${team} ]]
      then
        log "ERROR" "${FUNCNAME[0]}" "${red}Setup directory ${team} already exists. If you need to rerun, please manually clear the directory first.${reset}"
        exit 1
      fi

      # log "INFO" "${FUNCNAME[0]}" "${cyan}Writing Terraform code to setup GitHub repositories for team |${purple}${team}${reset}| for CSP |${green}${teams[${team}]}${reset}|"
      log "INFO" "${FUNCNAME[0]}" "${cyan}Writing Terraform code to setup GitHub repositories for team |${purple}${team}${reset}|"

      ## create platform-team area to sed into, and template project and workspace child mod repo files
      #
      for dir in platform-team terraform-tfe-project terraform-tfe-workspaces
      do
        mkdir -p "preparation/${team}/${dir}"
        rCode=${?}
        if [[ ${rCode} > 0 ]]
        then
          log "ERROR" "${FUNCNAME[0]}" "${red}Failed to mkdir ${team}/${dir}${reset}"
          exit ${rCode}
        fi
      done

      ## collate platform-team repo files by sedding in the team name, ready for tf-insertion into the created top-level example repo
      #
      sed "s/%%TEAM%%/${team}/g" templates/platform-team/main.tf      > preparation/${team}/platform-team/main.tf
      sed "s/%%TEAM%%/${team}/g" templates/platform-team/terraform.tf > preparation/${team}/platform-team/terraform.tf
      sed "s/%%TEAM%%/${team}/g" templates/platform-team/README.md    > preparation/${team}/platform-team/README.md
      sed "s/%%TEAM%%/${team}/g" templates/platform-team/terraform.auto.tfvars    > preparation/${team}/platform-team/terraform.auto.tfvars
      cp templates/platform-team/variables.tf                           preparation/${team}/platform-team/variables.tf

      ## collate the project and workspaces child module repo files needed to create child mod in the respective team PMR
      #
      for mod in workspaces project
      do
        cp templates/terraform-tfe-${mod}/* preparation/${team}/terraform-tfe-${mod}
        rCode=${?}
        if [[ ${rCode} > 0 ]]
        then
          log "ERROR" "${FUNCNAME[0]}" "${red}Failed to cp templates/terraform-tfe-${mod}/* preparation/${team}/terraform-tfe-${mod}${reset}"
          exit ${rCode}
        fi
      done

      ## create directory to hold the terraform code we run to deploy/populate the platform-team top level repo plus the two child module repos
      #
      mkdir -p "preparation/${team}/tf"
      rCode=${?}
      if [[ ${rCode} > 0 ]]
      then
        log "ERROR" "${FUNCNAME[0]}" "${red}Failed to mkdir ${team}/tf${reset}"
        exit ${rCode}
      fi

      ## We need space to create a tf config to run the above files into GH.
      #
      cat > "preparation/${team}/tf/${team}.tf" <<EOF
## tf hackathon
## Set up objects required by the hackathon day which fall outside of the instruqt
## environment, and are thus not destroyed when the environment expires.
## Therefore, a terraform destroy run is required to clean up.
#
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    tfe = {
      version = ">= 0.68.2"
      source  = "hashicorp/tfe"
    }
    github = {
      version = ">= 6.6.0"
      source  = "integrations/github"
    }
  }
}

provider "tfe" {}
provider "github" {
  owner = "${team}"
}

## Platform Team top level repo/workspace and population
#
resource "github_repository" "main" {
  name               = "platform-team"
  description        = "Repository which backs the top-level platform team HCP Terraform workspace"
  gitignore_template = "Terraform"
  visibility         = "private"
  has_issues         = false
  has_projects       = false
}

resource "github_repository_file" "platform_team_readme_md" {
  repository          = github_repository.main.name
  branch              = "main"
  file                = "README.md"
  content             = file(pathexpand("../platform-team/README.md"))
  overwrite_on_create = true
}

resource "github_repository_file" "platform_team_main_tf" {
  repository          = github_repository.main.name
  branch              = "main"
  file                = "main.tf"
  content             = file(pathexpand("../platform-team/main.tf"))
  overwrite_on_create = true
}

resource "github_repository_file" "platform_team_variables_tf" {
  repository          = github_repository.main.name
  branch              = "main"
  file                = "variables.tf"
  content             = file(pathexpand("../platform-team/variables.tf"))
  overwrite_on_create = true
}

resource "github_repository_file" "platform_team_terraform_tf" {
  repository          = github_repository.main.name
  branch              = "main"
  file                = "terraform.tf"
  content             = file(pathexpand("../platform-team/terraform.tf"))
  overwrite_on_create = true
}

## HCPT/TFE Project child module repo
#
resource "github_repository" "project_child_module" {
  name               = "terraform-tfe-project"
  description        = "Repository which backs the child module which deploys an HCPT/TFE project"
  gitignore_template = "Terraform"
  visibility         = "private"
  has_issues         = false
  has_projects       = false
}

resource "github_repository_file" "project_child_module_readme_md" {
  repository          = github_repository.project_child_module.name
  branch              = "main"
  file                = "README.md"
  content             = file(pathexpand("../terraform-tfe-project/README.md"))
  overwrite_on_create = true
}

resource "github_repository_file" "project_child_module_main_tf" {
  repository          = github_repository.project_child_module.name
  branch              = "main"
  file                = "main.tf"
  content             = file(pathexpand("../terraform-tfe-project/main.tf"))
  overwrite_on_create = true
}

resource "github_repository_file" "project_child_module_variables_tf" {
  repository          = github_repository.project_child_module.name
  branch              = "main"
  file                = "variables.tf"
  content             = file(pathexpand("../terraform-tfe-project/variables.tf"))
  overwrite_on_create = true
}

resource "github_repository_file" "project_child_module_outputs_tf" {
  repository          = github_repository.project_child_module.name
  branch              = "main"
  file                = "outputs.tf"
  content             = file(pathexpand("../terraform-tfe-project/outputs.tf"))
  overwrite_on_create = true
}

resource "github_release" "project_child_module" {
  repository = github_repository.project_child_module.name
  tag_name   = "v1.0.0"
  draft      = false
  prerelease = false
  depends_on = [
    github_repository.project_child_module,
    github_repository_file.project_child_module_readme_md,
    github_repository_file.project_child_module_main_tf,
    github_repository_file.project_child_module_variables_tf,
    github_repository_file.project_child_module_outputs_tf
  ]
}

## HCPT/TFE Workspaces child module repo
#
resource "github_repository" "workspaces_child_module" {
  name               = "terraform-tfe-workspaces"
  description        = "Repository which backs the child module which deploys HCPT/TFE workspaces"
  gitignore_template = "Terraform"
  visibility         = "private"
  has_issues         = false
  has_projects       = false
}

resource "github_repository_file" "workspaces_child_module_readme_md" {
  repository          = github_repository.workspaces_child_module.name
  branch              = "main"
  file                = "README.md"
  content             = file(pathexpand("../terraform-tfe-workspaces/README.md"))
  overwrite_on_create = true
}

resource "github_repository_file" "workspaces_child_module_main_tf" {
  repository          = github_repository.workspaces_child_module.name
  branch              = "main"
  file                = "main.tf"
  content             = file(pathexpand("../terraform-tfe-workspaces/main.tf"))
  overwrite_on_create = true
}

resource "github_repository_file" "workspaces_child_module_variables_tf" {
  repository          = github_repository.workspaces_child_module.name
  branch              = "main"
  file                = "variables.tf"
  content             = file(pathexpand("../terraform-tfe-workspaces/variables.tf"))
  overwrite_on_create = true
}

resource "github_repository_file" "workspaces_child_module_outputs_tf" {
  repository          = github_repository.workspaces_child_module.name
  branch              = "main"
  file                = "outputs.tf"
  content             = file(pathexpand("../terraform-tfe-workspaces/outputs.tf"))
  overwrite_on_create = true
}

resource "github_release" "workspaces_child_module" {
  repository = github_repository.workspaces_child_module.name
  tag_name   = "v1.0.0"
  draft      = false
  prerelease = false
  depends_on = [
    github_repository.workspaces_child_module,
    github_repository_file.workspaces_child_module_readme_md,
    github_repository_file.workspaces_child_module_main_tf,
    github_repository_file.workspaces_child_module_variables_tf,
    github_repository_file.workspaces_child_module_outputs_tf
  ]
}

## HCPT/TFE oauth connection from HCPT/TFE to GitHub for the purposes of publishing modules into the PMR
#
resource "tfe_oauth_client" "main" {
  organization     = "${team}"
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = "${gh_token}"
  service_provider = "github"
}

## HCPT/TFE private module registry entry
#
resource "tfe_registry_module" "project" {
  vcs_repo {
    display_identifier = "${team}/terraform-tfe-project"
    identifier         = "${team}/terraform-tfe-project"
    oauth_token_id     = tfe_oauth_client.main.oauth_token_id
  }
  depends_on = [
    github_repository.project_child_module,
    github_repository_file.project_child_module_readme_md,
    github_repository_file.project_child_module_main_tf,
    github_repository_file.project_child_module_variables_tf,
    github_repository_file.project_child_module_outputs_tf
  ]
}

resource "tfe_registry_module" "workspaces" {
  vcs_repo {
    display_identifier = "${team}/terraform-tfe-workspaces"
    identifier         = "${team}/terraform-tfe-workspaces"
    oauth_token_id     = tfe_oauth_client.main.oauth_token_id
  }
  depends_on = [
    github_repository.workspaces_child_module,
    github_repository_file.workspaces_child_module_readme_md,
    github_repository_file.workspaces_child_module_main_tf,
    github_repository_file.workspaces_child_module_variables_tf,
    github_repository_file.workspaces_child_module_outputs_tf
  ]
}
EOF

      pushd "preparation/${team}/tf" &>/dev/null
      rCode=${?}
      if [[ ${rCode} > 0 ]]
      then
        log "ERROR" "${FUNCNAME[0]}" "${red}Failed to pushd "preparation/${team}/tf" &>/dev/null${reset}"
        exit ${rCode}
      fi

      run_tf

      popd &>/dev/null
      rCode=${?}
      if [[ ${rCode} > 0 ]]
      then
        log "ERROR" "${FUNCNAME[0]}" "${red}Failed to popd &>/dev/null${reset}"
        exit ${rCode}
      fi
    done
  # fi


  elif [[ "${arg}" == "run" ]]
  then
    ## Run the hackathon elements into the instruqt environment (deploy VPC/VNet with terraform then use packer to insert flag machine images).
    ## Do this at the start of the hackathon.
    #
    export region=${AWS_DEFAULT_REGION}
    setup_environment_for_cloud_build
    this_user=$(id -p | head -1 | awk '{print $NF}')
    pushd packer &>/dev/null
    log "INFO" "${FUNCNAME[0]}" "sed \"s/%%USERNAME%%/${this_user}/g\" phoenix-capture-flag.pkr.hcl.tmpl > phoenix-capture-flag.pkr.hcl"
    sed "s/%%USERNAME%%/${this_user}/g" phoenix-capture-flag.pkr.hcl.tmpl > phoenix-capture-flag.pkr.hcl
    if [[ ! -f "phoenix-capture-flag.pkr.hcl" ]]
    then
      log "ERROR" "${FUNCNAME[0]}" "Packer manifest has not been generated. Bye."
      exit 1
    fi
    popd &>/dev/null
    build_cloud_images && rm -f packer/phoenix-capture-flag.pkr.hcl
    log "INFO" "${FUNCNAME[0]}" "Finished"
    unset AWS_BUILD_VPC AWS_BUILD_SUBNET ARM_BUILD_VNET ARM_BUILD_SUBNET

  # elif [[ "${arg}" == "down" ]]
  #   ## drop the hackathon elements outside of the instruqt environment (undo prep).
  #   ## Run this after the hackathon has formally completed.
  #   #
  # else
  #   usage
  fi
  exit 0





  # export region=${AWS_DEFAULT_REGION}
  # setup_environment_for_cloud_build

  # ## solicit username and update the paths in the packer build file
  # #
  # this_user=$(id -p | head -1 | awk '{print $NF}')
  # pushd packer &>/dev/null
  # log  "INFO" "${FUNCNAME[0]}" "sed \"s/%%USERNAME%%/${this_user}/g\" phoenix-capture-flag.pkr.hcl.tmpl > phoenix-capture-flag.pkr.hcl"
  # sed "s/%%USERNAME%%/${this_user}/g" phoenix-capture-flag.pkr.hcl.tmpl > phoenix-capture-flag.pkr.hcl
  # if [[ ! -f "phoenix-capture-flag.pkr.hcl" ]]
  # then
  #   log "ERROR" "${FUNCNAME[0]}" "Packer manifest has not been generated. Bye."
  # fi
  # popd &>/dev/null

  # build_cloud_images #&& rm -f packer/phoenix-capture-flag.pkr.hcl
  # log "INFO" "${FUNCNAME[0]}" "Finished"
  # unset AWS_BUILD_VPC AWS_BUILD_SUBNET ARM_BUILD_VNET ARM_BUILD_SUBNET
}

main "$@"
#
## jah brendan
