# CUE CMP for ArgoCD

Enables ArgoCD to render kubernetes manifests using `cue`.

It supports `cue eval` and `cue cmd` and a sub-set of the available options for these sub-commands.


## Installation

The only thing necessary to get started with this cmp are three things:

1. A `ConfigMap` resource containing the `config.yaml` of the cmp
1. A patched `argocd-repo-server`
1. An image with `cue` installed

In the following section we provide `kubectl` snippets to apply the provided `ConfigMap` and
`Deployment` patches to install `argocd-cmp-cuelang`. Please be aware that we assume that
ArgoCD has been installed into the `argocd` namespace, and the name of the ArgoCD Repo Server
deployment is `argocd-repo-server`; should this **not** be the case, you will need to update
the snippets accordingly.

### Using the argocd-cmp-cuelang sidecar

We provide a ready-to-go Container on our GHCR repo, which comes with a baked-in plugin YAML
for `argocd-cmp-cuelang`. You can patch your deployment as follows:

```shell
> cue mod get github.com/deepbrook/argocd-cmp-cuelang@<PLUGIN_VERSION>  # Install the module in your local cue.mod
> cue cmd patch github.com/deepbrook/argocd-cmp-cuelang/config > patch.yaml
> cat patch.yaml  # Inspect the patch
> kubectl patch deployment --namespace=argocd argocd-repo-server --patch-file=patch.yaml
```

Note: if you prefer mounting the `plugin.yaml` as a volume from a `ConfigMap` instead, pass `-t cm=true` to `cue cmd patch`. It will declare the needed volumes and mounts, and generate a ConfigMap manifest for you.

Restart the pods and you're done!

### Additional Tooling

By default, the patch provided by this module uses our own minimal image for the sidecar.
It's a minimal image with nothing besides `cue` itself installed.

Should you require additional tooling for your projects, for example if you invoke
other binaries using `tool/exec` in your `cue` workflows, you will have to provision these
yourself.

You have several options to achieve this:

1. **Use Your Own Image** (recommended)
   Building your own minimal image for your use-case is recommended, as it avoids bloated third-party images
   and minimizes security risks, as the [config management plugins are granted a level of trust](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#config-management-plugins) by ArgoCD.

1. **Use a Third-Party Image**
   Using an image other than `ghcr.io/deepbrook/argocd-cmp-cuelang` will make it easier for your cue workflows to install
   dependencies (if they're not already included with the image).

1. **Fetch needed binaries during your cue workflows**
   This option makes sense for dependencies which you only need for very few or single repositories/apps.
   Essentially, you'll have to use `tool/http` to fetch a binary from a remote source of your choice, and
   `tool/exec` to run it (note that you're limited to `cue`'s standard library and it currently has no support for unpacking archives).


## Usage

The plugin can be used as soon as a `.cue` file is detected in the source directory.

Note that you'll need have a module initialized in the source directory or your project's root, if you're intending to load packages.

### Generating Manifests with `cue eval`

By default, the cmp will invoke `cue eval` on the Application's `spec.source.path`.

Since ArgoCD expects a stream of YAML/JSON objects as the output of the command, we can't
simply evaluate the `cue` files with `--out=yaml/--out=json`.

As an example, assume the following `manifests.cue` file:

```yaml
package manifests

manifestA: {
  kind: "Secret"
  apiVersion: "v1"
  metadata: name: "SecretA"
  stringData: { my_secret_greeting: "hellou!"}
}

manifestB: {
  kind: "Secret"
  apiVersion: "v1"
  metadata: name: "SecretB"
  stringData: { my_secret_greeting: "Ahoi!"}
}
```

Evaluating this with `cue eval --out=yaml` would produce a single YAML document, as you can see here:

```shell
❯ cue eval .:manifests --out=yaml
manifestA:
  kind: Secret
  apiVersion: v1
  metadata:
    name: SecretA
  stringData:
    my_secret_greeting: hellou!
manifestB:
  kind: Secret
  apiVersion: v1
  metadata:
    name: SecretB
  stringData:
    my_secret_greeting: Ahoi!
```

ArgoCD would raise an error in this case, as the produced YAML document isn't a valid K8s manifest, nor a stream thereof.

Thus, the CMP assumes two things about your package:

- Your package declares a `manifests` field
- The field's value is a YAML or JSON-encoded string

To achieve this, for the example above, the following changes would be needed:

```yaml
package manifests

import "encoding/yaml"  // "encoding/json" is fine too

manifestA: {
  kind: "Secret"
  apiVersion: "v1"
  metadata: name: "SecretA"
  stringData: { my_secret_greeting: "hellou!"}
}

manifestB: {
  kind: "Secret"
  apiVersion: "v1"
  metadata: name: "SecretB"
  stringData: { my_secret_greeting: "Ahoi!"}
}

manifests: yaml.MarshalStream([manifestA, manifestB])
```

`argocd-cmp-cuelang` then evaluates successfully to a stream of valid YAML documents:

```shell
> cue eval -e manifests --out=text
kind: Secret
apiVersion: v1
metadata:
  name: SecretA
stringData:
  my_secret_greeting: hellou!
---
kind: Secret
apiVersion: v1
metadata:
  name: SecretB
stringData:
  my_secret_greeting: Ahoi!

```

Note that `-e manifests` and the output format `text` are default values and are set automatically; however,
you can customize these values by setting the following parameters:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: expressions
          array: ["yourExpression"]  # You may declare multiple expressions
        - name: output
          string: "yaml"  # May be one of "yaml", "json" or "text".
```

Should you require inputs via the `-t/--injections` flag, you can set them as follows:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: tags
          array:
            - tagA=someValue
            ...
```


### Generating Manifests with `cue cmd`

If you'd rather use a cue workflow command, you may specify the parameter `cue-command: "cmd"` under `spec.source.plugin.parameters`:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: cue-command
          string: "cmd"
```

By default, the CMP assumes that there is only a single cue package in the source's path. Additionally, the
default CUE workflow invoked is `build`. These values can be modified using the following parameters:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: workflow
          string: "your-workflow-command-name"
        - name: package
          string: "./path/to/package"
```

When declaring a relative path to a package using the `package` parameter, please note that `cue` is run
in the application source's `path` (accessed via the environment variable `ARGOCD_APP_SOURCE_PATH` by the plugin),
which is *relative* to your repository's root.

Should your workflow require inputs via the `-t/--injections` flag, you can set them as follows:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: tags
          array:
            - tagA=someValue
            ...
```

[per the official docs]: https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#installing-a-config-management-plugin