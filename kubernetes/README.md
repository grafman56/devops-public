# Kubernetes templates

A small two-tier application: nginx serves a ConfigMap page, PostgreSQL stores
data, an Ingress exposes the site, and NetworkPolicy limits traffic.

Manifests use API versions that are stable in Kubernetes 1.37.1. The pinned
images are in `VERSIONS.md`.

## Layout

```
base/                     shared manifests, apply through an overlay
  configmap.yaml          page content
  deployment.yaml         nginx, probes, resource requests and limits
  service.yaml            ClusterIP service
  ingress.yaml            host app.example.internal, ingressClassName nginx
  hpa.yaml                autoscaling/v2, CPU target 70 percent
  pdb.yaml                policy/v1, minAvailable 1
  networkpolicy.yaml      default deny, then allow ingress and DNS
  postgres/
    statefulset.yaml      PostgreSQL 18.6, 5Gi volumeClaimTemplate
    service.yaml          headless service for stable pod DNS
    networkpolicy.yaml    allow web to reach 5432 only
    backup-cronjob.yaml   nightly pg_dump to a PVC
    backup-pvc.yaml
    secret.example.yaml   shape only, do not commit real values
overlays/
  dev/                    namespace example-dev, one replica, dev host
  prod/                   namespace example-prod, three replicas, larger limits
helm/
  values-ingress-nginx.yaml
```

`base` has no Namespace object. Each overlay creates its own. Apply an
overlay, never `base` directly.

## Prerequisites

- A cluster at 1.37.1, or a newer version that still serves these APIs.
- A default StorageClass for the PostgreSQL and backup claims.
- `metrics-server` for the HorizontalPodAutoscaler. Without it the HPA reports
  unknown metrics and stays at minReplicas.
- An ingress controller. Install it before the overlay:

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.15.1 \
  --namespace ingress-nginx --create-namespace \
  -f kubernetes/helm/values-ingress-nginx.yaml
```

## Create the database secret

The StatefulSet reads `db-credentials`. Apply the example only if you changed
the password first. The safer path:

```
kubectl create namespace example-dev
kubectl -n example-dev create secret generic db-credentials \
  --from-literal=POSTGRES_DB=appdb \
  --from-literal=POSTGRES_USER=appuser \
  --from-literal=POSTGRES_PASSWORD='replace-me'
```

The prod overlay uses its own namespace. Repeat with `-n example-prod`.

## Render and check before applying

```
kubectl kustomize kubernetes/overlays/dev > /tmp/dev.yaml
kubeconform -strict -kubernetes-version 1.37.1 -summary /tmp/dev.yaml
kubectl apply --dry-run=server -f /tmp/dev.yaml
```

`kubectl apply --dry-run=server` needs a live cluster and catches admission
errors that a schema check cannot.

## Apply

```
kubectl apply -k kubernetes/overlays/dev
kubectl -n example-dev rollout status statefulset/db --timeout=180s
kubectl -n example-dev rollout status deployment/web --timeout=180s
kubectl -n example-dev get pods,svc,ingress,hpa,pdb
```

Both overlays use the same object names inside different namespaces. The
StatefulSet pod is `db-0`, and the backup CronJob reaches it by the stable name
`db-0.db-headless`.

## Test the site

Port-forward avoids DNS work:

```
kubectl -n example-dev port-forward svc/web 8080:80
curl -sS http://127.0.0.1:8080/
```

Through the ingress, once DNS or `/etc/hosts` points at the ingress address:

```
curl -sS -H 'Host: app.dev.example.internal' http://<ingress-address>/
```

The TLS secret `example-tls` is referenced but not created. Either create it
with cert-manager, or remove the `tls` block for a plain HTTP lab.

## What to inspect and change

1. `kubectl -n example-dev describe hpa web` shows whether CPU metrics
   arrive. Generate load with `kubectl run` and a loop against the service.
2. Delete the pod `db-0`. The StatefulSet recreates it with the same name
   and the same claim.
3. Apply a patch that removes the readiness probe and watch the rollout. Put
   it back.
4. Change the NetworkPolicy to allow port 5432 from every pod, then confirm
   with a test pod in another namespace. Put the selector back.

## Remove

```
kubectl delete -k kubernetes/overlays/dev
kubectl delete namespace example-dev
```

The StatefulSet volume claims survive a namespace delete only if the namespace
itself is deleted with its contents; deleting the overlay leaves the claims.
Delete them explicitly when you want a clean slate.

## References

- Workloads: https://kubernetes.io/docs/concepts/workloads/
- Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- NetworkPolicy: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- HorizontalPodAutoscaler: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- Kustomize: https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/
- ingress-nginx chart: https://github.com/kubernetes/ingress-nginx/tree/controller-v1.15.1/charts/ingress-nginx
- PostgreSQL image notes: https://hub.docker.com/_/postgres
