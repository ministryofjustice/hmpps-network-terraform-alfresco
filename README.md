# hmpps-network-terraform-alfresco

USING TERRAFORM
================

A shell script has been created to automate the running of terraform.
Script takes the following arguments

* environment_type: Target environment eg dev - prod - int
* action_type: Operation to be completed eg plan - apply - test - output
* AWS_TOKEN: token to use when running locally eg hmpps-token

Example

```
python docker-run.py --env dev --action test --token hmpps-token
```

TERRAGRUNT
===========

## DOCKER CONTAINER IMAGE

Container repo [hmpps-engineering-tools](https://github.com/ministryofjustice/hmpps-engineering-tools)


Terraform - automated run
==========================

A python script has been written up: docker-run.py.

The script takes arguments shown below:

```
python docker-run.py -h
usage: docker-run.py [-h] --env ENV --action {apply,plan,test,output}
                     [--component COMPONENT] [--token TOKEN]

terraform docker runner

optional arguments:
  -h, --help            show this help message and exit
  --env ENV             target environment
  --action {apply,plan,test,output}
                        action to perform
  --component COMPONENT
                        component to run task on
  --token TOKEN         aws token for credentials
````

## Usage

When running locally provide the token argument:

```
python docker-run.py --env dev --action test --token hmpps-token
```

When running in CI environment:

```
python docker-run.py --env dev --action test
```


INSPEC
======

[Reference material](https://www.inspec.io/docs/reference/resources/#aws-resources)

## TERRAFORM TESTING

#### Temporary AWS creds 

Script __scripts/aws-get-temp-creds.sh__ has been written up to automate the process of generating the creds into a file __env_configs/inspec-creds.properties__

#### Usage

```
sh scripts/generate-terraform-outputs.sh
sh scripts/aws-get-temp-creds.sh
source env_configs/inspec-creds.properties
inspec exec ${inspec_profile} -t aws://${TG_REGION}
```

#### To remove the creds

```
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
export AWS_PROFILE=hmpps-token
source env_configs/dev.properties
rm -rf env_configs/inspec-creds.properties
```