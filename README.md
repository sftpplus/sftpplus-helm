# SFTPPlus Helm chart

This chart deploys one SFTPPlus controller and one or more file transfer workers. The controller manages configuration and the workers serve SFTP and HTTPS file transfers. No ingress or persistent volume claim is created.

## Prerequisites

- A Kubernetes cluster with Helm 3.
- An existing persistent volume claim in the release namespace, writable by UID and GID 1000. The controller and all workers mount the same claim. Use storage that supports simultaneous mounts on the selected nodes. If the claim only supports one node, select that node for both deployments.
- A trial or full version of SFTPPlus as a container image containing `/opt/sftpplus/bin/admin-commands.sh`. The default is `proatria/sftpplus-trial:latest`. Contact support@proatria.com to get access to the full version. If the image is private, create an image pull secret in the release namespace.
- Two initial passwords: one for the `admin` Web Manager account and one shared by the controller and workers. Keep each password in a separate local file and do not commit those files.

## Install from this directory

With an existing claim named `sftpplus-data`, run from the repository root:

```sh
helm install production . \
  --namespace sftpplus --create-namespace \
  --set-string storage.existingClaim=sftpplus-data \
  --set-file credentials.adminPassword=/path/to/admin-password.txt \
  --set-file credentials.workerPassword=/path/to/worker-password.txt
```

The password files should contain the password without a trailing newline. Helm stores these values in the release record, and the chart creates Kubernetes Secrets from them. Restrict access to the files and the release record.

For a private image, pass an existing pull secret with `--set 'imagePullSecrets[0].name=YOUR_SECRET'`. To select nodes, provide a values file such as:

```yaml
nodeSelector:
  kubernetes.io/hostname: storage-node
```

To use another image, set `image.repository` and `image.tag`. Set `worker.replicaCount` to scale the file transfer workers. The controller always has one replica.

## Install from the Helm repository

This GitHub repository serves the Helm chart through GitHub Pages. In the repository Pages settings, select **Deploy from a branch**, then choose `main` and `/docs`. Set `helm.sftpplus.com` as the custom domain and point its DNS CNAME record to `sftpplus.github.io`. Commit the generated `docs/` files to `main`. Once `https://helm.sftpplus.com/index.yaml` is available, run:

```sh
helm repo add sftpplus https://helm.sftpplus.com/
helm repo update sftpplus
helm install production sftpplus/sftpplus \
  --namespace sftpplus --create-namespace \
  --set-string storage.existingClaim=sftpplus-data \
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
| `storage.existingClaim` | Required name of the existing persistent volume claim. |
| `credentials.adminPassword` | Required initial password for the `admin` account. |
| `credentials.workerPassword` | Required initial shared worker password. |
| `image.repository`, `image.tag`, `image.pullPolicy` | Optional container image settings. Default image: `proatria/sftpplus-trial:latest`. |
| `imagePullSecrets` | Names of existing Kubernetes image pull secrets, such as `[{name: registry-pull-secret}]`. |
| `nodeSelector` | Kubernetes node selection rules for both deployments. |
| `worker.replicaCount` | Number of worker pods. |

## Services and initial configuration

The chart creates two NodePort Services. Run `kubectl -n sftpplus get svc` to find the assigned external ports. The controller Service exposes Web Manager over HTTPS on target port 10020. The worker Service exposes SFTP on 10022 and HTTPS file transfers on 10443. The unsecured Web Manager and worker debug services are disabled. Workers connect to the controller through its release-specific Service name.

The controller initializes `configuration/server.ini` on the claim only when that file does not exist. At that time it hashes both passwords and generates a TLS certificate and SSH host key. Existing configuration is kept on upgrades and restarts. Changing `credentials.adminPassword` or `credentials.workerPassword` in Helm values does not change passwords in an already initialized `server.ini`. Change the administrator password in Web Manager. Coordinate a worker password change with the cluster pool password in Web Manager and restart the workers with the updated Helm value.

The chart does not manage the claim's lifecycle. Uninstalling the release leaves its data in place. To start a fresh installation, use a new empty claim.

## Publish a chart version

For each release, increase `version` in `Chart.yaml`, then run from the repository root:

```sh
./build-repository.sh
```

The script lints and packages the chart into `docs/sftpplus-VERSION.tgz`, then generates `docs/index.yaml`, `docs/index.html`, and `docs/CNAME`. The index uses chart URLs under `https://helm.sftpplus.com/`. The script keeps existing chart packages in `docs/` and adds them to the new index. Commit the generated `docs/` files with the chart source. GitHub Pages publishes that directory when the commit reaches `main`.
