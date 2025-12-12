# CUE CMP for ArgoCD

Enables ArgoCD to render kubernetes manifests using `cue`.

It supports `cue eval` and `cue cmd` and a sub-set of the available options for these sub-commands.


## Installation

The only thing necessary to get started with this cmp are three things:

1. A `ConfigMap` resource containing the `config.yaml` of the cmp
1. A patched `argocd-repo-server`
1. An image with `cue` installed

In the following sections we provide `kubectl` snippets to apply the provided `ConfigMap` and
`Deployment` patches to install `argocd-cmp-cuelang`. Please be aware that we assume that
ArgoCD has been installed into the `argocd` namespace, and the name of the ArgoCD Repo Server
deployment is `argocd-repo-server`; should this **not** be the case, you will need to update
the snippets accordingly.

### Creating the CMP `ConfigMap`

The `config.yaml` required by ArgoCD must be supplied via a `ConfigMap` resource (unless you're using your own image, in which case you may bake the config into it).

Either copy it from this repository, or let the `argocd-cmp-cuelang` module generate one for you:

```shell
> cue cmd create-cm github.com/deepbrook/argocd-cmp-cuelang:plugin > cm.yaml
```

Inspect the config with `cat cm.yaml` or an editor of your choice, if you like.
Then, apply:

```
> kubectl apply -f cm.yaml --namespace=argocd
```


### Patching the `argocd-repo-server` deployment

As [per the official docs][], you'll have to patch your `argocd-repo-server`, adding
a sidecar container to it.

Again, you can generate a patch using the  `argocd-cmp-cuelang` module:

```shell
> cue cmd create-patch github.com/deepbrook/argocd-cmp-cuelang:plugin > patch.yaml
```

Feel free to inspect and adapt `patch.yaml` as you need; by default, we use `cuelange/cue`
as the image for the side-car.

> [!info]
> If you're using `cue cmd` and your workflows require additional
> tools or binaries, see [Additional Tooling](##-additional-tooling) on how to provide those.

Finally, patch the deployment:

```shell
> kubectl patch deployment argocd-repo-server --patch-file=patch.yaml --namespace=argocd
```

Restart the container, and you're good to go!

### Additional Tooling

By default, the patch provided by this module uses `cuelang/cue` as the sidecar's image.
It's a minimal image with nothing besides `cue` itself installed.

Should you require additional tooling for your projects, for example if you invoke
other binaries using `tool/exec` in your `cue` workflows, you will have to provision these
yourself.

You have several options to achieve this:

1. **Use Your Own Image** (recommended)
   Building your own minimal image for your use-case is recommended, as it avoids bloated third-party images
   and minimizes security risks, as the [config management plugins are granted a level of trust](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#config-management-plugins) by ArgoCD.

1. **Fetch needed binaries during your cue workflows**
   This option makes sense for dependencies which you only need for very few or single repositories/apps.
   Essentially, you'll have to use `tool/http` to fetch a binary from a remote source of your choice, and
   `tool/exec` to run it (note that `cue`'s standard library currently has no support for unpacking archives).

1. **Use a Third-Party Image**
   Using an image other than `cuelang/cue` (default) will make it easier for your cue workflows to install
   dependencies (if they're not already included with the image). It's a good alternative to option 1, if you
   find yourself installing the same tools over and over.


## Usage

The plugin can be used as soon as a `.cue` file is detected in the repository.

### Generating Manifests with `cue eval`

By default, the cmp will invoke `cue eval` on the Application's `spec:source:path`.

Since ArgoCD expects a stream of YAML documents as the output of the command, we can't
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

## Parameters

You can inspect the available parameters by running:

```
> cue cmd parameters github.com/deepbrook/argocd-cmp-cuelang
```

[per the official docs]: https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#installing-a-config-management-plugin