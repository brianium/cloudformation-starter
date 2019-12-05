include config.mk

.PHONY: all
all: environment=production
all: clean bootstrap application automation

.PHONY: application
application_dependencies := out/application.output.yaml validate-application
application: stack_prefix=$(application_name)-$(environment)
application: $(application_dependencies)
	$(deploy) --parameter-overrides \
	Environment=$(environment)

.PHONY: create-change-set/application
create-change-set/application: stack_prefix=$(application_name)-$(environment)
create-change-set/application: $(application_dependencies)
	$(call create-change-set,application) \
	--parameters ParameterKey="Environment",ParameterValue="$(environment)" 

.PHONY: automation
automation: out/automation.output.yaml validate-automation
	$(deploy) --parameter-overrides \
	BootstrapStackName=$(stack_prefix)-bootstrap \
	Environment=$(environment) \
	GitHubOwner=$(github_owner) \
	GitHubRepo=$(github_repo) \
	GitHubBranch=$(github_branch) \
	GitHubDevelopBranch=$(github_develop_branch) \
	GitHubToken=$(github_token) \
	StackName=$(stack_prefix)-application \
	ChangeSetName=$(stack_prefix)-application-changes

.PHONY: bootstrap
bootstrap: out/bootstrap.output.yaml validate-bootstrap
	$(deploy) --parameter-overrides BucketName=$(aws_build_bucket)

.PHONY: clean
clean:
	rm -rf out

out:
	mkdir -p out

out/%.output.yaml: out
	$(package)

out/config.application.json: out
	@echo "{" > $@
	@echo "  \"Parameters\": {" >> $@
	@echo "    \"Environment\": \"$(environment)\"" >> $@
	@echo "  }" >> $@
	@echo "}" >> $@
	
validate-%:
	$(AWS) cloudformation validate-template --template-body file://infrastructure/src/cloudformation/$*.yaml
	
