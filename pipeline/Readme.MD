# Pipeline Demo

## Setup.

Spin up the environment mentioned in the Readme file on the repo 

### Clone repo

git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git

### setup namespace 
``` 
   oc login --token=<<TOKEN>> --server=<<SERVER_API_URL>>
   oc new-project stt 
```   

### Create Required Tasks.

Note :- Update the following file under pipeline to get the secrets correct.

#### redhat-na-ssa-tektonpipeline-pull-secret.yaml

Get the docker config json from quay account ([quay.io/redhat_na_ssa](https://quay.io/organization/redhat_na_ssa?tab=robots))

Robot account : redhat_na_ssa+tektonpipeline

view the token and replace the content <<DOCKER CONFIG JSON FROM QUAY ACCOUNT>>

```
   cd pipeline
   oc apply -f .
```   

### Execute the pipeline
Select Pipeline `stt-ubi-pipeline` , Actions -> Start

Update the parameter `stackrox-endpoint` with the current environment host. The value of the end point can be got from demo environment.

`source_dir` parameter set it to VolumeClaim Template
`reports` parameter set it to VolumeClaim Template

hit `start` button.
