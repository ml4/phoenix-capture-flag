# phoenix-capture-flag

A Packer build which takes a CSP market place image and adds a flag to capture, creating a [phoenix image](https://martinfowler.com/bliki/PhoenixServer.html).
Initial build focuses on AWS and Azure.

The build adds a file called /etc/flag with contents instantiated in an environment variable per the build.

Generally not shared with customers in a gameathon style as they might edit their own phoenix packer build :D

## Use
- Create a directory called `keys` and put all public ssh keys in it called blah.pub
- Instantiate the following:
  - `export AWS_DEFAULT_REGION=""`
  - `export AWS_ACCESS_KEY_ID=""` (Access Key ID from Instruqt)
  - `export AWS_SECRET_ACCESS_KEY=""` (Secret Access Key from Instruqt)
- Run `az login` and instantiate the following:
  - `export ARM_SUBSCRIPTION_ID=""` (Subscription ID from Instruqt)
  - `export ARM_CLIENT_ID=""` (service principal ID from instruqt)
  - `export ARM_CLIENT_SECRET=""` (service principal password from instruqt)
  - `export ARM_TENANT_ID=""` (Tenant ID from instruqt).
- - You can get this with az account show --query id --output tsv
- Update the `flag` file - this is copied to `/etc` on the built image
- Update the `phoenix-capture-flag.pkr.hcl` file changing the owner private ssh key used to do the default build
```shell
ssh_keypair_name          = "ml4"
ssh_private_key_file      = "~/.ssh/ml4"
```
- Run Terraform commands to setup the non-default VPC in the AWS account:
```shell
terraform init
terraform plan
terraform apply -auto-approve
```
- This will output:
- - AWS: the subnet and VPC IDs. Instantiate the following from this output:
- - - `export AWS_BUILD_SUBNET=""`
- - - `export AWS_BUILD_VPC=""`
- - Azure: the RG, VNET and Subnet IDs. Instantiate the following (check the values are correct):
- - -  `AZURE_BUILD_RG`
- - - `export AZURE_BUILD_VNET="phoenix-vnet"`
- - - `export AZURE_BUILD_SUBNET="phoenix-subnet"`
- Get the latest ubuntu build AMI reference from the AWS console or a CLI equivalent and instantiate `AWS_BUILD_AMI` with it
- -
```shell
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
  --output text
```
- You should have six AWS environment variables instantiated before you run make.
- Run `make` (or `make list` first to get an idea)

## Cleaning
- If using an ephemeral environment that removes your CSP objects, run `make clean` to remove the Terraform state for that and start again.
