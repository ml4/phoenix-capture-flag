
all:
	. ./run.sh

list:
	cat Makefile

clean:
	rm -rf  ./.terraform ./.terraform.lock.hcl ./terraform.tfstate ./terraform.tfstate.backup
	@echo "now run: unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUILD_AMI ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET"
