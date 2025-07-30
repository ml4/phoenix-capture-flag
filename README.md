# phoenix-capture-flag

A Packer build which takes a CSP market place image and adds a flag to capture, creating a [phoenix image](https://martinfowler.com/bliki/PhoenixServer.html).
Initial build focuses on AWS and Azure.

The build adds a file called /etc/flag with contents instantiated in an environment variable per the build.

## Use
- Create a file called ssh.keys with this format
<github_handle_1>,<ssh-public key>
<github_handle_2>,<ssh-public key>
...
- Run `aws configure` to insert your AWS credentials
- Update the `flag` file - this is copied to `/etc` on the built image
- Run this to get some latest AWS AMI marketplace base image IDs and pick one
```shell
aws ec2 describe-images --owners 099720109477 --query "Images[*].[CreationDate,Name,ImageId]" --filters "Name=name,Values=ubuntu-minimal*24.04*" --region ${AWS_DEFAULT_REGION} --output table | sort -r | grep -Ev "^[-+]|DescribeImages" | head -3
```
- Update the `phoenix-capture-flag.pkr.hcl` file changing the owner private ssh key used to do the default build (the above SSH public keys will be added into the default user authorized_keys)
```shell
ssh_keypair_name          = "ml4"
ssh_private_key_file      = "~/.ssh/ml4"
```
