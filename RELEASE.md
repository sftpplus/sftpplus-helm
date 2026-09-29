# Publishing chart versions

The same Helm repository at `https://helm.sftpplus.com/` can serve multiple
versions of the SFTPPlus chart. Each published version has its own package in
`docs/`, and `docs/index.yaml` lists the available versions.

## Publish a new version

1. Update `version` in `Chart.yaml` for every chart release (for example,
   from `0.1.0` to `0.2.0`). `appVersion` identifies the SFTPPlus application
   version and only needs to change when that version changes.
2. Add the version, publication date, and user-visible changes to
   [release-notes.md](release-notes.md). Use the date the version first
   appears in the Helm repository.
3. Run `./build-repository.sh` from the repository root. It lints and packages
   the chart, then rebuilds `docs/index.yaml` from the chart packages in
   `docs/`.
4. Check that the new package, such as `docs/sftpplus-0.5.0.tgz`, and the
   previous packages are present. Keep previous packages so their versions
   remain in the regenerated index and available to install.
5. Commit and push `Chart.yaml`, the chart changes, the new package, and
   `docs/index.yaml` to `main`. GitHub Pages serves the `docs/` directory.

Do not replace the package for an already published chart version. Increment
`version` for each release.

## Select a version

After the new files are published, users can refresh and list the available
versions:

```sh
helm repo add sftpplus https://helm.sftpplus.com/
helm repo update sftpplus
helm search repo sftpplus/sftpplus --versions
```

Specify a chart version when installing or upgrading. For example, to upgrade
an existing release while retaining its current values:

```sh
helm upgrade production sftpplus/sftpplus \
  --namespace sftpplus --version 0.5.0 --reuse-values
```

The selected chart version is independent of the SFTPPlus `appVersion`.
