
all:
	./run.sh

list:
	cat Makefile

clean:
	rm -rf  ./.terraform ./.terraform.lock.hcl ./terraform.tfstate ./terraform.tfstate.backup
	