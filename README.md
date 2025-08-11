# phoenix-capture-flag

A Packer build which takes a CSP market place image and adds a flag to capture, creating a [phoenix image](https://martinfowler.com/bliki/PhoenixServer.html).
Initial build focuses on AWS and Azure.

The build adds a file called /etc/flag with contents instantiated in an environment variable per the build.

Generally not shared with customers in a gameathon style as they might edit their own phoenix packer build :D

## Use
These have to be run every 6 hours.  Note that the run.sh script will prompt to ask if you want Terraform deployment of the non-default VPC in case you are debugging the packer build and only want that bit run again.
- Go to Instruqt and run the Cloud Sandbox deployment. 1 * six hour access to all three main clouds results
- Block the text from the webpage with the creds in to a file called secret.txt and run `add_vars.sh secret.txt` to output the pastable env vars to set your shell up for the packer build. `**/secret*` is in the .gitignore file.
- Create a directory called `keys` and put all public ssh keys in it called blah.pub
- Update the `packer/flag` file - this is copied to `/etc` on the built image
- Run the following from *this directory* to instantiate the required env vars, run Terraform to prepare a non-default VPC/VNet for the Packer run, then runs Packer.
```
. run.sh     # Instantiate vars from the Instruqt ephmeral account setup web page
```

This will result in
1. Non-default VPC exists in the AWS account and VNet in the Azure account (nothing in the GCP account as yet).
1. Packer-built AMI from a recent Ubuntu image in the AWS account and machine image ID in the Azure account (nothing in GCP).

### Next steps
Write repos with monolithic TF for the customer to break into child mods for their work with the HCPT private mod reg (Further env setup pending).

## Cleaning
- If using an ephemeral environment that removes your CSP objects, run this.
```shell
rm -rf  ./.terraform ./.terraform.lock.hcl ./terraform.tfstate ./terraform.tfstate.backup
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUILD_AMI ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET
```
