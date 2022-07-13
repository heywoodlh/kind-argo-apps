#!/usr/bin/env bash

deps=(kind helm kubectl git readlink)
missing_deps=''

script_root_dir=$(dirname -- "$( readlink -f -- "$0";  )";)

for dep in "${deps[@]}"
do

    if ! command which ${dep} &> /dev/null 
    then
	missing_deps+="${dep} "	
    fi
done

[[ -n "${missing_deps[@]}" ]] && printf "Missing the following dependencies: ${missing_deps[@]} \nExiting.\n" && exit 1

create_cluster() {
    kind create cluster --name=argo-apps
    create_status=$?
   
    ## If argo-apps kind cluster was created successfully
    if [[ ${create_status} == 0 ]]
    then
	[[ -e ${script_root_dir}/apps/templates/root.yaml ]] && cd ${script_root_dir}
	[[ -e ${script_root_dir}/apps/templates/root.yaml ]] || working_dir=$(pwd) && random_string=${RANDOM} && git clone https://github.com/heywoodlh/argo-apps "/tmp/argo-apps-${random_string}" && cd "/tmp/argo-apps-${random_string}"

	# Install argo-cd 
	helm repo list | grep -q argo-cd || helm repo add argo-cd https://argoproj.github.io/argo-helm
	helm dep update charts/argo-cd

	helm install argo-cd charts/argo-cd/

	helm template apps/ | kubectl apply -f -

	[[ -n ${random_string} ]] && cd ${working_dir} && rm -rf /tmp/argo-apps-${random_string}
    
    fi
}

destroy_cluster() {
    kind delete cluster --name=argo-apps
}

if ! kind get clusters | grep -q argo-apps
then
    echo "argo-apps kind cluster already installed -- destroy it and start over? (y/n)"
    read destroy_response

    if [[ ${destroy_response} == "y" ]] || [[ ${destroy_response} == "Y" ]]
    then
	destroy_cluster && echo 'argo-apps cluster destroyed' && create cluster
    fi
else
    create_cluster
fi
