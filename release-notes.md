# Helm chart release notes

## 0.6.0 (2026-10-04)

- Added a shared `service_name` pod label set to the Helm release name for the controller and worker, making their logs easier to query together in Loki and Grafana.

## 0.5.0 (2026-09-29)

- Added optional cert-manager Certificate creation for `ingress.host`. The controller and worker Ingresses can share the issued TLS Secret; an existing Issuer or ClusterIssuer is required.
- Updated the on-premises and Vultr examples to use the chart-managed Certificate. When upgrading from Ingress-based issuance, remove the old issuer annotations and Certificate before enabling this option for the same Secret.
- Removed empty password placeholders from the example values so existing releases can upgrade with `--reuse-values` without supplying the passwords again.

## 0.4.0 (2026-09-28)

- Removed the repeated chart name from resources. For a release named `sftpplus`, the Services are now `sftpplus-admin-https` on port 10020, optional `sftpplus-admin-http` on port 10019, and `sftpplus-worker` for file transfers.
- Changed the default PVC name to `<release>-storage`. Set `storage.claimName` to the existing claim when upgrading so its data remains in use.
- Update external TCP forwarding rules and any other references to the renamed Services before upgrading. Long release names are shortened with a stable hash; use names of 51 characters or fewer to keep the full release name.
- For multiple releases in one cluster, use a different release name and PVC for each. Give each installation its own ingress hostname, TLS Secret, and external SFTP port or load balancer route.

## 0.3.0 (2026-09-28)

- Added an optional init container to set the shared claim root permissions for storage such as Vultr VFS.
- Set `sftpplus-worker-pool` as the default worker pool and made the worker debug manager use HTTP.
- Added Vultr and on-premises examples with release-specific resource names and ingress routes.
- When upgrading a release that already has an initialized claim, set `workerDeployment.poolName` to the pool name in its existing `server.ini` if it differs from the new default.

## 0.2.1 (2026-09-27)

- Corrected the initial HTTPS file transfer service name in the generated SFTPPlus configuration.
- Documented that the initial `test_user` account and `DEFAULT_GROUP` are disabled by default.

## 0.2.0 (2026-09-27)

- Added support for an existing or chart-created persistent volume claim, with configurable storage settings.
- Added configurable NodePort and LoadBalancer Services, HTTP ingress routes, and example values for Scaleway and Vultr.
- Added separate controller and worker pod settings, including ServiceAccounts and pod metadata for workload identity.
- Added initial configuration for HTTP worker synchronization and ingress host paths.

## 0.1.0 (2026-09-27)

- Initial chart for an SFTPPlus controller and file transfer workers sharing a persistent volume claim.
