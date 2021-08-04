default: build
.PHONY: build

prep:
	rm -rf network 
	rm -rf internetgateway natgateway peering-connection routes security-groups vpc

get_configs:
	rm -rf env_configs
	git config --global advice.detachedHead false
	git clone -b $(ENV_CONFIGS_VERSION) $(ENV_CONFIGS_REPO) env_configs

get_network: prep
	git clone -b $(NETWORK_VERSION) $(NETWORK_REPO) network
	rm -rf network/.git network/Jenkinsfile network/*.sh network/.gitignore network/README.md network/LICENSE network/.github
	cp -r network/{internetgateway,natgateway,peering-connection,routes,security-groups,vpc} $(PWD)/

init:
	rm -rf $(COMPONENT)/.terraform/terraform.tfstate

plan: init
	sh run.sh $(ENVIRONMENT_NAME) plan $(COMPONENT) || (exit $$?)

destroy:
	sh run.sh $(ENVIRONMENT_NAME) destroy $(COMPONENT) || (exit $$?)

apply:
	sh run.sh $(ENVIRONMENT_NAME) apply $(COMPONENT) || (exit $$?)

output:
	sh run.sh $(ENVIRONMENT_NAME) output $(COMPONENT) || (exit $$?)

start: restart
	docker-compose exec builder env| sort

stop:
	docker-compose down

cleanup:
	docker-compose down -v --rmi local

restart: stop
	docker-compose up -d


local_plan: restart
	docker-compose exec builder make plan

local_apply: restart
	docker-compose exec builder make apply

local_output: restart
	docker-compose exec builder make output
