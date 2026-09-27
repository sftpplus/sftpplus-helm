# SFTPPlus Helm chart

This chart deploys one SFTPPlus controller and one or more file transfer workers. The controller manages configuration and the workers serve SFTP and HTTPS file transfers. The chart can create a shared persistent volume claim and optional HTTPS ingress routes.

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

## Helm values

**From version:** 6.1.0

| Value | Purpose |
| --- | --- |
| `storage.createIfMissing`, `storage.claimName` | Use the named PVC if present, or create it from `claimSpec` if missing. An empty name defaults to `<release>-sftpplus-storage`. |
| `storage.claimSpec` | Full `spec` of a chart-created PersistentVolumeClaim, including access modes, storage request, and optional storage class. |
| `storage.retain` | Keep a chart-created claim after uninstall (default: true). |
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
| `workerDeployment.replicaCount`, `workerDeployment.poolName` | Number of worker pods and the shared cluster pool name. |
| `workerDeployment.sync.protocol` | Controller connection protocol: `https` by default, or `http` when `adminService.http.enabled=true`. |
| `adminService.http` | Optional internal HTTP Web Manager Service on port 10019. |
| `workerService.httpFiles`, `workerService.workerDebug` | Optional HTTP file transfer and worker manager ports. |
| `ingress.admin.backendPort`, `ingress.worker.backendPort` | Select the named Service port used by each ingress route. |
| `ingress.admin.workerDebug` | Optional worker manager route on the admin ingress. |

## Services and initial configuration

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

The controller initializes `configuration/server.ini` on the claim only when that file does not exist. At that time it hashes both passwords and generates a TLS certificate and SSH host key. Existing configuration is kept on upgrades and restarts. Changing `credentials.adminPassword` or `credentials.workerPassword` in Helm values does not change passwords in an already initialized `server.ini`. Change the administrator password in Web Manager. Coordinate a worker password change with the cluster pool password in Web Manager and restart the workers with the updated Helm value.

With `storage.createIfMissing=true`, the chart uses an existing claim with
`storage.claimName` or creates it if missing. Chart-created claims are retained on uninstall by default; set `storage.retain=false` only if deleting the release should also delete its claim. Back up the claim separately. To start with fresh data, use a new empty claim.

## HTTP ingress example

For a reverse proxy that terminates TLS and enforces basic auth, enable the
internal HTTP manager Service, HTTP file transfer, and worker debug routes.
Set `workerDeployment.sync.protocol: http` to connect workers through the
internal manager Service. The example in the server repository at
`infrastructure/sftpplus-helm-values.yaml` configures these routes for
`/admin`, `/worker-admin`, and `/`, respectively. Provide the ingress class,
TLS Secret, authentication Secret, and controller for your cluster. These
settings affect `server.ini` only when initializing a new claim; changing
Helm values does not rewrite an existing configuration file.

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

Example values for [Scaleway](examples/scaleway-values.yaml) and
[Vultr](examples/vultr-values.yaml) show storage classes and external access
based on the deployment examples. Adjust storage classes, hostnames, TLS
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
