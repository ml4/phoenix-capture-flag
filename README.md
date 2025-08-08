# phoenix-capture-flag

A Packer build which takes a CSP market place image and adds a flag to capture, creating a [phoenix image](https://martinfowler.com/bliki/PhoenixServer.html).
Initial build focuses on AWS and Azure.

The build adds a file called /etc/flag with contents instantiated in an environment variable per the build.

Generally not shared with customers in a gameathon style as they might edit their own phoenix packer build :D

## Use
- Create a directory called `keys` and put all public ssh keys in it called blah.pub
- Update the `flag` file - this is copied to `/etc` on the built image
- Run the following from this directory to instantiate the required env vars, run Terraform to prepare a non-default VPC/VNet for the Packer run, then runs Packer.
```
. run.sh     # Instantiate vars from the Instruqt ephmeral account setup web page
```

## Cleaning
- If using an ephemeral environment that removes your CSP objects, run this.
```shell
rm -rf  ./.terraform ./.terraform.lock.hcl ./terraform.tfstate ./terraform.tfstate.backup
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUILD_AMI ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET
```
