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

create_network() {
    docker network ls | grep -q kind && docker network rm kind
    docker network create --driver=bridge --ip-range=172.28.5.0/24 --subnet=172.28.0.0/16 --gateway=172.28.5.1 kind
}

create_cluster() {

cat <<EOF | kind create cluster --name=argo-apps --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 9080
    protocol: TCP
  - containerPort: 443
    hostPort: 9443
    protocol: TCP
EOF

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

	## Install nginx-ingress with custom kind patches
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

	## Enable kustomize with argo-cd
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: default
data:
  kustomize.buildOptions: --enable-helm
  application.instanceLabelKey: argocd.argoproj.io/instance
  repositories: |
    - type: helm
      name: stable
      url: https://charts.helm.sh/stable
    - type: helm
      name: argo-cd
      url: https://argoproj.github.io/argo-helm
  url: http://localhost:9080/argo
EOF
    
    fi
}

destroy_cluster() {
    kind delete cluster --name=argo-apps
    docker network rm kind
}

if kind get clusters | grep -q argo-apps
then
    echo "argo-apps kind cluster already installed -- destroy it and start over? (y/n)"
    read destroy_response

    if [[ ${destroy_response} == "y" ]] || [[ ${destroy_response} == "Y" ]]
    then
	destroy_cluster && echo 'argo-apps cluster destroyed' && create_cluster
    fi
else
    create_network
    create_cluster
fi
