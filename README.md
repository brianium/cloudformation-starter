# cloudformation-starter

A lightweight template for using Make to manage infrastructure as code via Make.

Attempts to let Make do what Make does best, and let other tools do their jobs as simply as possible.

## Why?

* A solid Make setup is super flexible!
* You can add and extend things all day every day!
* Raw CloudFormation (yaml) works out of the box with the AWS cli
* You can usually acheive things in yaml before you can with the [cdk](https://docs.aws.amazon.com/cdk/latest/guide/home.html)
* It's my preference! (for now)

## Usage

Clone this guy as a start to a new project. The end goal is to be able to run this to acheive a radical infrastructure on AWS.

```
$ make
```

Just tweak your configuration and let er rip!

## Makefile

The included Makefile is broken up into two files:

* Makefile
* config.mk

The `config.mk` file contains variables, macros, and functions. It is mostly data. The `Makefile` file contains some dynamic and fixed targets that are useful for getting started.

## Config

The `config.mk` file is where we assign values to variables for use in the `Makefile`. It also contains macros and functions. Some areas of note:

### Executables

The `EXECUTABLES` variable contains a list of executables required within the environment executing `make`. If your process requires a command line program, put it here. Out of the box it looks like this:

`EXECUTABLES = jq aws`

This requires [jq](https://stedolan.github.io/jq/) for JSON processing and of course the [aws cli](https://aws.amazon.com/cli/).

### AWS Config

These variables require values required for the aws cli to do it's job properly.

```
aws_region ?= us-east-2
aws_profile ?= default
aws_account_id ?= 123456789101112
aws_build_bucket ?= build-iehib5fu
stack_prefix ?= myapp
```

#### aws_build_bucket

It is possible to create a bucket without a name via CloudFormation. The `bootstrap` target will create a bucket with this name. Supplying a name allows the `package` macro to use the bucket without having to query CloudFormation stack outputs. The name doesn't matter a ton - just as long as you can find it later should you need to. Can effectively be a set and forget value.

### stack_prefix

This value should/will be applied to all stacks created via the `Makefile`. This ensures a relative consistency in stacks created via this method - i.e `myapp-application`, `myapp-bootstrap`, etc..

### Application Settings

These variables are used for specific application needs. This list can and should grow as your application does.

```
environment ?= staging
security_group_ids ?= sg-12345
subnet_ids ?= subnet-1234,subnet-5678
```

### Git and Github

These variables handle configuring AWS to integrate cleanly with GitHub and Git based workflows.

```
github_owner ?= myorgoruser
github_repo ?= myrepo
github_branch ?= master
github_develop_branch ?= develop
github_token_parameter ?= /path/to/github_token
version_type ?= patch
```

#### github_token_parameter

Most AWS services require a GitHub token to create webhooks, pull source, etcc.. This variable should
contain a parameter name pointing to a parameter in [SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html). This value will be looked up using the aws cli. The `--with-decryption` flag is used, so store that parameter as a `SecureString`. This value will be placed in a variable called `github_token`.

#### version_type

This isn't directly used in the starter, but is useful for defining the type of version being released in a Git based workflow.


## Targets

Targets are executed when using Make using the form

```
$ make target-name
```

### Dynamic Targets

Dynamic targets take advantage of Make placeholders - a.k.a `%`

#### out/%.output.yaml

This really just expands the `package` macro in order to call `aws cloudformation package` in a super flexible way. 

**Usage**:

```
$ make out/application.output.yaml
```

This will package the yaml file located at `infrastructure/src/cloudformation/application.yaml`. This works for all files located in `infrastructure/src/cloudformation/` - just replace `application` with the file that needs to be packaged.


#### validate-%:

**Usage:**

```
$ make validate-application
```

This runs `aws cloudformation validate-template` on the yaml file identified by the placeholder `%`. In the example above, this would be `application.yaml`.

### Fixed Targets

The default `all` target looks like this:

```
all: clean bootstrap application automation
```

This is run when simply executing `make`, and is used to create an entire system on AWS.

#### bootstrap

Creates foundational resources. This should for the most part just be the bucket identified by `$(aws_build_bucket)`. This bucket is a requirement for packaged templates and builds done in the `automation` target.

#### application

This should be resources relevant to your working application. It can and should orchestrate different services and resources to make your application SHINE.

#### automation

Handles CI/CD via [CodeBuild](https://aws.amazon.com/codebuild/) and [CodePipeline](https://aws.amazon.com/codepipeline/).

Out of the box this includes a production build for building a change set to production, a test build that executes unit tests for pull requests against the `$(github_develop_branch)`, and a pipeline to organize steps in a production release.

Buildspecs used by codebuild fit neatly into the `infrastructure/src/buildspecs` directory.

## Go forth!

This is just a starting point using tried and true tools. It should be able to grow and change as needed.

### Nested stacks

As needs grow, and things become more complex - [nested stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-nested-stacks.html) can be a useful tool for organizing the `application` and `automation` layers. `application.yaml` and `automation.yaml` can just be composed of nested stacks, while `application/` and `automation/` directories can contain nested stacks.

Perhaps using a directory structure like this:

```
application.yaml
application/
-- database.yaml
-- api.yaml
automation.yaml
automation/
-- code-builds.yaml
-- sns-topics.yaml
bootstrap.yaml
```
