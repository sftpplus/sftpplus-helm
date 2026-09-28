# SFTPPlus Helm chart

This chart deploys one SFTPPlus controller and one or more file transfer workers. The controller manages configuration and the workers serve SFTP and HTTPS file transfers. The chart can create a shared persistent volume claim and optional HTTPS ingress routes.

SFTPPlus deployment on Kubernetes is simple at its core: it uses one
container image and an initializer that creates a standard `.ini`
configuration file. We encourage you to write Kubernetes YAML tailored to
your requirements for maximum control and simplicity. See
[sftpplus-kubernetes](https://github.com/sftpplus/sftpplus-kubernetes) for
examples that use the full range of SFTPPlus capabilities.

This chart is more complex because it accommodates a variety of Kubernetes
environments. It focuses on a proof-of-concept installation and uses one
shared storage volume for configuration and user files. SFTPPlus supports
multiple storage options that this chart does not expose.

For a production deployment, contact the SFTPPlus support team at
support@proatria.com for guidance. Keep the Web Manager admin interface on a
separate ingress or load balancer from public file transfers. The examples in
this chart can share one public hostname for a proof of concept.

## Prerequisites

- A Kubernetes cluster with Helm 3.
- A persistent volume claim writable by UID and GID 1000, either existing or created by the chart. The controller and all workers mount the same claim. Use a ReadWriteMany storage class for pods on different nodes. ReadWriteOnce storage confines the pods to one node.
- A trial or full version of SFTPPlus as a container image containing `/opt/sftpplus/bin/admin-commands.sh`. The default is `proatria/sftpplus-trial:latest`. Contact support@proatria.com to get access to the full version. If the image is private, create an image pull secret in the release namespace.
- Two initial passwords: one for the `admin` Web Manager account and one shared by the controller and workers. Keep each password in a separate local file and do not commit those files.

## Install from this directory

To use an existing claim named `sftpplus-data`, run from the repository root:

```sh
helm install production . \
  --namespace sftpplus --create-namespace \
  --set-string storage.claimName=sftpplus-data \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

The password files should contain the password without a trailing newline. Helm stores these values in the release record, and the chart creates Kubernetes Secrets from them. Restrict access to the files and the release record.

For a private image, pass an existing pull secret with `--set 'imagePullSecrets[0].name=YOUR_SECRET'`. To select nodes, provide a values file such as:

```yaml
nodeSelector:
  kubernetes.io/hostname: storage-node
```

To use another image, set `image.repository` and `image.tag`. Set `workerDeployment.replicaCount` to scale the file transfer workers. The controller always has one replica.

## Install from the Helm repository

This GitHub repository serves the Helm chart through GitHub Pages. In the repository Pages settings, select **Deploy from a branch**, then choose `main` and `/docs`. Set `helm.sftpplus.com` as the custom domain and point its DNS CNAME record to `sftpplus.github.io`. Commit the generated `docs/` files to `main`. Once `https://helm.sftpplus.com/index.yaml` is available, run:

```sh
helm repo add sftpplus https://helm.sftpplus.com/
helm repo update sftpplus
helm install production sftpplus/sftpplus \
  --namespace sftpplus --create-namespace \
  --set-string storage.claimName=sftpplus-data \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

After a new chart version is published, update the local index and upgrade the release:

```sh
helm repo update sftpplus
helm upgrade production sftpplus/sftpplus \
  --namespace sftpplus --reuse-values
```

`helm repo update` refreshes the list of available charts. `helm upgrade` applies the new chart. `--reuse-values` keeps the existing PVC, image, and password settings. Review the new chart's values before upgrading if any settings need to change.

Chart 0.3.0 changes the default worker pool name to `sftpplus-worker-pool`.
When upgrading an existing initialized claim, check its pool name in
`server.ini` and set `workerDeployment.poolName` to that value if different.
The chart does not rewrite an existing `server.ini`.

## Helm values

**From version:** 6.1.0

| Value | Purpose |
| --- | --- |
| `storage.createIfMissing`, `storage.claimName` | Use the named PVC if present, or create it from `claimSpec` if missing. An empty name defaults to `<release>-storage`. |
| `storage.claimSpec` | Full `spec` of a chart-created PersistentVolumeClaim, including access modes, storage request, and optional storage class. |
| `storage.retain` | Keep a chart-created claim after uninstall (default: true). |
| `storage.permissions` | Optional root init container that sets the shared claim root owner, group, and mode. Disabled by default; available from chart 0.3.0. |
| `adminService`, `workerService` | Service type (`NodePort`, `LoadBalancer`, or `ClusterIP`), ports, annotations, and optional load balancer settings. |
| `ingress.host` | Optional common hostname used for `accepted_origins` in a newly initialized `server.ini` and as the default Ingress rule host. |
| `ingress.admin`, `ingress.worker` | Optional HTTPS ingress routes with independent host overrides, class names, annotations, and TLS secrets. |
| `credentials.adminPassword` | Required initial password for the `admin` account. |
| `credentials.workerPassword` | Required initial shared worker password. |
| `image.repository`, `image.tag`, `image.pullPolicy` | Optional container image settings. Default image: `proatria/sftpplus-trial:latest`. |
| `imagePullSecrets` | Names of existing Kubernetes image pull secrets, such as `[{name: registry-pull-secret}]`. |
| `nodeSelector` | Kubernetes node selection rules for both deployments. |
| `adminDeployment.serviceAccountName`, `workerDeployment.serviceAccountName` | Existing ServiceAccount names for the controller and workers. |
| `adminDeployment.templateMetadata`, `workerDeployment.templateMetadata` | Extra pod template labels and annotations. Custom labels override defaults. |
| `workerDeployment.replicaCount`, `workerDeployment.poolName` | Number of worker pods and the shared cluster pool name. The default pool is `sftpplus-worker-pool`. |
| `workerDeployment.sync.protocol` | Controller connection protocol: `https` by default, or `http` when `adminService.http.enabled=true`. |
| `adminService.http` | Optional internal HTTP Web Manager Service on port 10019. |
| `workerService.httpFiles`, `workerService.workerDebug` | Optional HTTP file transfer and worker manager ports. The worker debug manager always uses HTTP (`_manager_unsecured`). |
| `ingress.admin.backendPort`, `ingress.worker.backendPort` | Select the named Service port used by each ingress route. |
| `ingress.admin.workerDebug` | Optional worker manager route on the admin ingress. |

## Services and initial configuration

Chart-managed resources use the Helm release name as a prefix, including
the default PVC name. For a release named `sftpplus`, the Services are
`sftpplus-admin-https` on port 10020, optional `sftpplus-admin-http` on port
10019, and `sftpplus-worker` for the transfer ports. The HTTPS manager is
reachable within the cluster at
`sftpplus-admin-https.<namespace>.svc.cluster.local:10020`.

Use release names of 51 characters or fewer to keep the full name in each
resource. For longer names, the chart shortens the release prefix to its
first 42 characters and appends an eight-character hash. This keeps Service
names within Kubernetes' 63-character limit. Check the rendered Service names
with `helm template` before adding external TCP forwarding rules.

The chart creates two external Services, which default to NodePort. Run `kubectl -n sftpplus get svc` to find the assigned ports or load balancer addresses. The controller Service exposes Web Manager over HTTPS on target port 10020. The worker Service exposes SFTP on 10022 and HTTPS file transfers on 10443. The unsecured Web Manager, HTTP file transfer, and worker debug services are disabled by default. Enable them only when an ingress controller or another trusted proxy handles public TLS and access control. Workers connect to the controller through its release-specific Service name.

Set `ingress.host` to the external hostname when using ingress. On first
initialization, the chart adds it as `accepted_origins` for the manager and
HTTPS file transfer services. It also sets `/admin` as the unsecured manager
base path and `/worker-admin` as the worker manager base path. The secure
manager base path stays empty. With no `ingress.host`, no `accepted_origins`
line is added and these base paths are empty. The unsecured manager and worker debug services can be enabled with
`adminService.http.enabled` and `workerService.workerDebug.enabled`. Component ingress hosts can
override the common host for Ingress rules, but `ingress.host` is the value
written to `server.ini`.

The initial configuration includes `test_user` and the default group (`DEFAULT_GROUP`) as disabled entries. They are blocked by default for security reasons and cannot be used to sign in or transfer files unless an administrator explicitly enables and configures them.

The controller initializes `configuration/server.ini` on the claim only when that file does not exist. At that time it hashes both passwords and generates a TLS certificate and SSH host key. Existing configuration is kept on upgrades and restarts. Changing `credentials.adminPassword` or `credentials.workerPassword` in Helm values does not change passwords in an already initialized `server.ini`. Change the administrator password in Web Manager. Coordinate a worker password change with the cluster pool password in Web Manager and restart the workers with the updated Helm value.

## Persistent storage on uninstall

With `storage.createIfMissing=true`, the chart uses the PVC named by
`storage.claimName` when it already exists, or creates it from
`storage.claimSpec` when it is missing. By default, a PVC created by the chart
is kept after `helm uninstall`. This is the default setting:

```yaml
storage:
  retain: true
```

The chart adds Helm's `helm.sh/resource-policy: keep` annotation to a PVC it
creates. Set `storage.retain: false` if Helm should delete a chart-created PVC
on uninstall. A PVC that existed before installation is not managed by this
chart and is not deleted on uninstall. Keep a separate backup of the PVC data.
To start with fresh data, use a new empty claim.

Some shared file systems mount a new claim root as `root:root` with mode
`0755`, so the SFTPPlus process running as UID 1000 cannot create its initial
configuration. Set `storage.permissions.enabled: true` to run a root init
container in the admin pod before SFTPPlus starts:

```yaml
storage:
  permissions:
    enabled: true
    uid: 1000
    gid: 1000
    mode: "0770"
```

The init container uses the selected SFTPPlus image and changes only the
claim root directory. It does not recursively change existing files. The
setting is disabled by default. On Vultr VFS, enable it for a new claim; if
reusing a claim, check existing file ownership separately.

## HTTP ingress example

For a reverse proxy that terminates TLS, enable the internal HTTP manager
Service, HTTP file transfer, and worker debug routes. Set
`workerDeployment.sync.protocol: http` to connect workers through the internal
manager Service. The [on-premises example](examples/onpremise-values.yaml)
configures `/admin`, `/worker-admin`, and `/` for these services. Provide an
ingress controller, ingress class, and TLS Secret for your cluster. The
example does not configure access control for the admin routes; protect them
before exposing them publicly. These settings affect `server.ini` only when
initializing a new claim; changing Helm values does not rewrite an existing
configuration file.

## Publish a chart version

For each release, increase `version` in `Chart.yaml`, then run from the repository root:

```sh
./build-repository.sh
```

The script lints and packages the chart into `docs/sftpplus-VERSION.tgz`, then generates `docs/index.yaml`, `docs/index.html`, and `docs/CNAME`. The index uses chart URLs under `https://helm.sftpplus.com/`. The script keeps existing chart packages in `docs/` and adds them to the new index. Commit the generated `docs/` files with the chart source. GitHub Pages publishes that directory when the commit reaches `main`.

## Cloud storage and external access

The same shared PVC is mounted by the controller and every worker. For multiple
nodes, choose a `ReadWriteMany` capable StorageClass, such as a file share
service supplied by the cluster or provider. A default block storage class
usually offers only `ReadWriteOnce`. Set `storage.claimName` to the desired claim name. With
`storage.createIfMissing=true`, the chart uses that claim when it exists
and otherwise creates it from `storage.claimSpec`. Set the access modes,
storage request, and storage class in `storage.claimSpec` for that case.
The Helm user needs permission to read PVCs in the release namespace. A
client-side `helm template` or dry run cannot check whether a claim exists;
use a server-side dry run to check the live cluster.
The StorageClass must exist in the cluster. Avoid changing the claim name or storage class during an upgrade;
migrate the data separately if storage changes.

For externally reachable SFTP, use `workerService.type=LoadBalancer` where
the cluster supports it, or `NodePort` behind an existing TCP load balancer.
Set `adminService.type=ClusterIP` to keep Web Manager internal, or expose it
through a separate LoadBalancer or an ingress. Services have independent
annotations for provider settings. Optional `ingress.admin` and
`ingress.worker` accept public HTTPS; an ingress controller must already be
installed. Set each ingress backend protocol annotation to match the selected
Service port. `ingress.admin.workerDebug.enabled` adds a worker manager
path to the admin ingress. SFTP is TCP and is never exposed by these HTTP ingress
rules. Restrict access to Web Manager at the load balancer, firewall, or
ingress layer.

The [example deployments](examples/README.md) include values for
[Scaleway](examples/scaleway-values.yaml),
[Vultr](examples/vultr-values.yaml), and
[on-premises Kubernetes](examples/onpremise-values.yaml). They show storage
classes and external access for each environment. Adjust storage classes, hostnames, TLS
secrets, load balancer annotations, and firewall rules for your cluster.
For AWS, Azure, and Google Kubernetes clusters, select a provisioner that
supports shared read/write mounts and use provider-specific Service
annotations if you need a private or pre-existing load balancer. No cloud
credentials or load balancer IDs are included in this chart.

Install with an example values file and the two initial passwords:

```sh
helm install production . --namespace sftpplus --create-namespace \
  -f examples/scaleway-values.yaml \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

## Workload identity and pod metadata

The chart can use existing ServiceAccounts independently for the controller
and workers. Set `adminDeployment.serviceAccountName` and
`workerDeployment.serviceAccountName`. The chart does not create ServiceAccounts or
configure a cloud identity. Add pod template labels or annotations under
`adminDeployment.templateMetadata` and `workerDeployment.templateMetadata`. User supplied labels
replace chart labels with the same keys. The Deployment and Service selectors
use the resulting instance and component labels so they still match the pods.
Changing those two selector labels after installation requires replacing the
Deployments because Kubernetes does not allow changing Deployment selectors.
The chart keeps its initialization checksum annotation so config changes still
restart pods.

To enable Azure Workload Identity, first configure the cluster's workload
identity issuer, webhook, and federated identity credential as described in
[Azure's workload identity guide](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview). The federated
credential's subject must match the ServiceAccount namespace and name used by
the release. Create the ServiceAccount in that namespace with the identity's
client ID annotation (and tenant ID annotation if needed):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sftpplus-workload-identity
  namespace: sftpplus
  annotations:
    azure.workload.identity/client-id: "<AZURE_CLIENT_ID>"
    # azure.workload.identity/tenant-id: "<AZURE_TENANT_ID>"
```

Then set the ServiceAccount name and the required Azure pod label for each
component in the Helm values:

```yaml
adminDeployment:
  serviceAccountName: sftpplus-workload-identity
  templateMetadata:
    labels:
      azure.workload.identity/use: "true"
workerDeployment:
  serviceAccountName: sftpplus-workload-identity
  templateMetadata:
    labels:
      azure.workload.identity/use: "true"
```

The chart references the existing ServiceAccount; it does not create it or
configure Azure. Restart existing pods after enabling workload identity so the
webhook can inject their projected tokens. This uses the chart's generic
metadata and ServiceAccount settings; other identity systems can use their own
names, labels, and annotations.
