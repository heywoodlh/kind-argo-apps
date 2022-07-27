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

Make sure you are in the context for the cluster with the following command:

```
kubectl config use-context kind-argo-apps
```

The cluster takes a few minutes to deploy all the applications, watch its progress with this command:

```
watch kubectl get applications
```

## Accessing Services:

### Argo CD:

Run the following command to access Argo at http://localhost:8080:

```
kubectl port-forward svc/argo-cd-argocd-server 8080:443
```

Then get the password for the `admin` user in Argo:

```
kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Kubeclarity:

Run the following command to access Kubeclarity at http://localhost:8080

```
kubectl port-forward svc/kubeclarity-kubeclarity 8080:8080
```
