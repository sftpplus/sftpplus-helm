# Example deployments

These values show three ways to use the SFTPPlus chart. Replace every uppercase
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
helm install RELEASE . --namespace YOUR_NAMESPACE \
  --create-namespace --values examples/vultr-values.yaml \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

Upgrade an existing release without supplying its passwords again:

```sh
helm upgrade RELEASE . --namespace YOUR_NAMESPACE \
  --reuse-values --values examples/vultr-values.yaml
```

`--reuse-values` retains the passwords stored in the existing Helm release.
The example values files omit password keys so they do not replace those
saved values with empty strings. New installations still require both passwords.

For Vultr SFTP, configure the nginx ingress controller's TCP services
ConfigMap to forward external port `10022` to the chart-created worker Service:

```yaml
10022: 'YOUR_NAMESPACE/RELEASE-worker:10022:PROXY'
```

The on-premises and Vultr examples enable cert-manager Certificate creation
for `ingress.host`. Install cert-manager and create the referenced
`ClusterIssuer` before installing either example. The issuer must be able to
validate the hostname; an HTTP-01 issuer needs public port 80 to reach its
challenge Ingress. cert-manager creates and renews the named TLS Secret.

The nginx LoadBalancer must expose TCP `10022`, and its firewall must allow
clients on that port. Each additional Helm release needs its own namespace or
release name, PVC, ingress hostname, TLS Secret, and external TCP port or load
balancer route. Keep `workerDeployment.replicaCount: 1` while exposing the
worker debug manager at `/worker-admin`.
