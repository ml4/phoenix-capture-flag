#!/usr/bin/env bash

## Check arguments
#
if [ $# -ne 1 ] || [ ! -f "$1" ]
then
  echo "Usage: $0 <file>"
  exit 1
fi

file_path=${1}

echo "Paste these onto your command line:"
echo

## Extract and echo AWS credentials
#
aws_access_key_id=$(grep -A1 '^Access Key ID:' "${file_path}" | tail -n1)
aws_secret_access_key=$(grep -A1 '^Secret Access Key:' "${file_path}" | tail -n1)
echo "export AWS_ACCESS_KEY_ID='${aws_access_key_id}'"
echo "export AWS_SECRET_ACCESS_KEY='${aws_secret_access_key}'"

## Extract and echo GCP project
#
gcp_project=$(grep -A1 '^Project ID:' "${file_path}" | tail -n1)
echo "export GOOGLE_PROJECT='${gcp_project}'"

## Extract and echo Azure credentials
#
arm_subscription_id=$(grep -A1 '^Subscription ID:' "${file_path}" | tail -n1)
arm_client_id=$(grep -A1 '^Service Principal ID:' "${file_path}" | tail -n1)
arm_client_secret=$(grep -A1 '^Service Principal Password:' "${file_path}" | tail -n1)
arm_tenant_id=$(grep -A1 '^Tenant ID:' "${file_path}" | tail -n1)
echo "export ARM_SUBSCRIPTION_ID='${arm_subscription_id}'"
echo "export ARM_CLIENT_ID='${arm_client_id}'"
echo "export ARM_CLIENT_SECRET='${arm_client_secret}'"
echo "export ARM_TENANT_ID='${arm_tenant_id}'"

