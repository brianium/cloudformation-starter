#############################################
# Validate Dependencies
#
# This is a simple mechanism for validating
# that required executables are available
# for use. Assumes the latest versions
#############################################

EXECUTABLES = jq aws
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "Executable $(exec) required")))

#############################################
# AWS Configuration
#
# Configure region, profile, and AWS environment
# - aws_build_bucket - this is the bucket name used for build output and packaged templates
#                      This could be created via CloudFormation without a name, but it is named
#                      to simplify debugging and usage via the cli for the `aws cloudformation package` command
# - stack_prefix - The stack prefix is used for applying a common prefix to all stacks managed by make
#############################################

aws_region ?= us-east-2
aws_profile ?= default
aws_account_id ?= 123456789101112
aws_build_bucket ?= build-iehib5fu
stack_prefix ?= myapp

export AWS_DEFAULT_REGION := $(aws_region)

ifeq ($(aws_profile),)
	AWS := aws
else
	export AWS_PROFILE := $(aws_profile)
	AWS := aws --profile $(aws_profile)
endif

#############################################
# Application settings
#
# Application settings are configuration
# relevant to a specific application
#############################################

environment ?= staging
security_group_ids ?= sg-12345
subnet_ids ?= subnet-1234,subnet-5678

#############################################
# Git and GitHub
#
# Assumes the use of GitHub - and more specifically
# a git flow re: https://nvie.com/posts/a-successful-git-branching-model/
# This can be changed to fit needs.
#
# - github_token_parameter - A parameter name used to 
#                            to lookup a GitHub token in SSM.
#                            Will be fetched using --with-decryption
#############################################

github_owner ?= myorgoruser
github_repo ?= myrepo
github_branch ?= master
github_develop_branch ?= develop
github_token_parameter ?= /path/to/github_token
github_token ?= $(shell $(AWS) ssm get-parameter --with-decryption --name $(github_token_parameter) | jq -r ".Parameter | .Value")
version_type ?= patch

#############################################
# Macros and Functions
#
# Macros and functions used to package and deploy
# templates based on convention - see Makefile for
# examples of $(package) and $(deploy) in action
#############################################

define package
	$(AWS) cloudformation package \
	--template-file infrastructure/src/cloudformation/$(subst out/,,$(subst .output,,$@)) \
	--s3-bucket $(aws_template_bucket) \
	--output-template-file $@
endef

define deploy
	$(AWS) cloudformation deploy \
	--stack-name $(stack_prefix)-$@ \
	--template-file out/$@.output.yaml \
	--capabilities CAPABILITY_IAM
endef
