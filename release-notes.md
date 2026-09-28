# Helm chart release notes

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
