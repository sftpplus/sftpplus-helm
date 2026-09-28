# Example deployments

These values show two ways to use the SFTPPlus chart. Replace every uppercase
`YOUR_...` placeholder with a value for your cluster. Keep passwords in local
files outside the repository and pass them with `--set-file`.

- [Vultr VFS](vultr-values.yaml) creates a shared VFS claim and exposes HTTP
  through nginx ingress. The ingress controller also needs a TCP forwarding
  rule for SFTP. The chart does not create that rule or the nginx LoadBalancer.
- [On-premises](onpremise-values.yaml) uses a specified PVC or creates it when
  missing. Select a ReadWriteMany storage class so the pods can run on
  different nodes. It shows Azure Workload Identity with an existing
  ServiceAccount. This identity
  is optional: remove both `serviceAccountName` values and their Azure pod
  labels when you do not use it. Replace the image and other site-specific
  names. The public example omits basic-auth annotations; restrict access to
  `/admin` and `/worker-admin` before exposing them publicly.
- [Scaleway](scaleway-values.yaml) shows shared SFS storage and external
  LoadBalancer Services.

From the chart repository root, render an example before installation:

```sh
helm template RELEASE . --namespace YOUR_NAMESPACE \
  --values examples/vultr-values.yaml \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

Then install with the same values:

```sh
helm upgrade --install RELEASE . --namespace YOUR_NAMESPACE \
  --create-namespace --values examples/vultr-values.yaml \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

For Vultr SFTP, configure the nginx ingress controller's TCP services
ConfigMap to forward external port `10022` to the chart-created worker Service:

```yaml
10022: 'YOUR_NAMESPACE/RELEASE-worker:10022:PROXY'
```

The nginx LoadBalancer must expose TCP `10022`, and its firewall must allow
clients on that port. Each additional Helm release needs its own namespace or
release name, PVC, ingress hostname, TLS Secret, and external TCP port or load
balancer route. Keep `workerDeployment.replicaCount: 1` while exposing the
worker debug manager at `/worker-admin`.
