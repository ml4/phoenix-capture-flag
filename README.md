# tf-capture-the-flag

This repo houses the code to manage an ephemeral multi-cloud capture-the-flag-style hackathon environment.
Use this to deploy the resources needed to boot a hackathon day attended by customer staff who want to learn more about HCP Terraform.
The form is
- How to break down monolithic, CE Terraform code into child modules backed by GitHub repos
- Deploy instances of these child modules (i.e. a network module and an compute module) using a workspace-based HCP Terraform-located root module.
- Login to the compute instance through the deployed bastion and call out the contents of /etc/flag (which is baked into the machine image in the ephemeral cloud account on the day)

## Init
0. Create the names of the two teams. The names must be unique across both GitHub and HCPT in order for the automation to succeed. Recommendation: 'hashicorp-<customer_name>-team1'
1. Create free tier GitHub organizations for each competing team using the _required clickops_ [here](https://github.com/organizations/plan) - Select 'My personal account' as the owner and add your staff collaborators.
2. Create personal HCPT organizations for each competing team using the _required clickops_ [here](https://app.terraform.io/app/organizations/new) - Do this because although a TFE provider resource exists, recently deleted orgs prevent recreation within the same period of time. See https://hashicorp.slack.com/archives/CPC3J8B8C/p1756304277156169 for more.
2. Run `hackathon.sh prep` which interactively prompts for each team name and the CSP they use.















- Terraform code to deploy non-default VPC/VNet in AWS and Azure account/subscription deployed by the Instruqt step (clickops)
- A Packer build which takes a CSP market place image in each case, adds packer/flag to /etc in the image to capture and writes a [phoenix image](https://martinfowler.com/bliki/PhoenixServer.html) to the account/subscription.
- GCP not supported at this time.
- This repo is for staff - generally not shared with customers in a gameathon style as they might edit their own phoenix packer build :D

## Use
These have to be run every 6 hours. Note that the `run.sh` script prompts if you want Terraform deployment of the non-default VPC in case you are debugging just the packer build and only want that bit run again.
1. [Go to Instruqt and run the Cloud Sandbox deployment](https://play.instruqt.com/manage/hashicorp-field-ops/tracks/gcp-aws). 1 * six hour access to all three main clouds results.
1. Block the text from the webpage with the creds in to a file called secret.txt and run `add_vars.sh secret.txt` to output the pastable env vars to set your shell up for the packer build. `**/secret*` is in the `.gitignore` file.
1. Run `./add_vars.sh secret_creds.txt`
1. Use `aws ec2 describe-images  --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' --query 'reverse(sort_by(Images, &CreationDate))[:1] | [0].ImageId' --output text` to get the latest Ubuntu 22 image for AWS in the default region you have configured.
1. Use `az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-jammy --sku 22_04-lts --location "UK South"` for the equivalent information for Azure
1. Paste the output of the above command into your bash shell to set the env vars up.
1. Create a directory called `keys` and put all public ssh keys in it called blah.pub etc.
1. Optionally update the `packer/flag` file.
1. Run the following from *this directory* to instantiate the required env vars, run Terraform to prepare a non-default VPC/VNet for the Packer run, then runs Packer.
```
. run.sh     # Instantiate vars from the Instruqt ephmeral account setup web page
```

## Result
1. Non-default VPC exists in the AWS account.
1. Non-default VNet in the Azure account.
1. Packer-built AMI from a recent Ubuntu image in the AWS account
1. Packer-built Azure machine image in the Azure account (resource group: phoenix-ctf-rg).

### Next steps
Write repos with monolithic TF for the customer to break into child mods for their work with the HCPT private mod reg (further env setup pending).

## Cleaning
- If using an ephemeral environment that removes your CSP objects, run this.
```shell
rm -rf  ./.terraform ./.terraform.lock.hcl ./terraform.tfstate ./terraform.tfstate.backup
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BASE_IMAGE_AMI ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET
```
