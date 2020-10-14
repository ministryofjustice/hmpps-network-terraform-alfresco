default: build
.PHONY: build

cleanup:
	rm -rf network
	rm -rf internetgateway natgateway peering-connection routes security-groups vpc

get_configs:
	rm -rf env_configs
	git config --global advice.detachedHead false
	git clone -b $(ENV_CONFIGS_VERSION) $(ENV_CONFIGS_REPO) env_configs

get_network: 
	git clone -b $(NETWORK_VERSION) $(NETWORK_REPO) network
	rm -rf network/.git network/Jenkinsfile network/*.sh network/.gitignore network/README.md network/LICENSE network/.github
	cp -r network/{internetgateway,natgateway,peering-connection,routes,security-groups,vpc} $(PWD)/

lambda_packages:
	rm -rf $(component)
	mkdir $(component)
	aws s3 sync --only-show-errors s3://$(ARTEFACTS_BUCKET)/projects/alfresco/lambda_functions/builds/$(LAMBDA_FUNCTIONS_VERSION)/ $(CODEBUILD_SRC_DIR)/$(component)/

plan: 
	sh run.sh $(ENVIRONMENT_NAME) plan $(component)

build: plan
	sh run.sh $(ENVIRONMENT_NAME) apply $(component)

destroy:
	sh run.sh $(ENVIRONMENT_NAME) destroy $(component)

