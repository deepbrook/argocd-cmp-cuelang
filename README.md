# CUE CMP for ArgoCD

## Installation

As per the official docs, you'll have to patch your `argocd-repo-server`, adding
a sidecar for any of the `cue` commands you want to provide as a CMP.
Additionally, you'll have to create a `ConfigMap` named `argocd-cmp-cuelang`
in the same namespace as your ArgoCD repo server deployment.

To make this easy, we've supplied workflow commands to generate these files for you:

```
> cue export -e patch github.com/deepbrook/argocd-cmp-cuelang:setup -o patch.yaml
> cue export -e cm github.com/deepbrook/argocd-cmp-cuelang:setup -o cm.yaml
```

Feel free to inspect and adapt `patch.yaml` as you need; by default, we use `cuelange/cue`
as the image for the side-car. If you require additional tools, you may either
adapt the `cm.yaml`'s `init` command, or use a cue workflow to fetch binaries and tools
necessary for your cue module to render correctly.

Once you're satisfied, you can then apply them with `kubectl`:

```shell
> kubectl apply -f cm.yaml --namespace=argocd
> kubectl patch deployment argocd-repo-server --namespace=argocd --patch-file=patch.yaml
```

Make sure to adapt `--namespace` and the deployment name as needed.

## Usage

The plugin can be used as soon as a `.cue` file is detected in the repository.

By default, the cmp will invoke `cue eval` on the source directory, using `--out=yaml` to format output.

If you'd rather usea cue workflow command, you may specify `cue-command: "cmd"` in the plugin configuration of your ArgoCD Application:

```
[...]
  plugin:
    parameters:
      - name: cue-command
        string: "cmd"
```

When declaring a relative path to a package using the `package` parameter, please note that `cue eval/cmd` is run in the source directory of your Application, which is relative to your repository's root.

## Parameters

You can inspect the available parameters by running:

```
> cue export -e help github.com/deepbrook/argocd-cmp-cuelang:params --out yaml
```