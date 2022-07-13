## argo-apps 

This is a demo Argo app of apps for testing meant to be deployed using [kind](https://kind.sigs.k8s.io/). As a demo environment, it will install multiple applications.

## Dependences:

- git: `sudo apt-get install -y git`
- GNU coreutils: `sudo apt-get install -y coreutils`
- kind: `sudo GOBIN=/usr/local/bin go install sigs.k8s.io/kind@v0.14.0`
- kubectl: [Kubectl install docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- helm: [Helm install docs](https://helm.sh/docs/intro/install/)

## Usage:

```
git clone https://github.com/heywoodlh/argo-apps
cd argo-apps
./kind.sh
```
