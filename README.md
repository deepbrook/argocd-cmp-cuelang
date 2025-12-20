# CUE CMP for ArgoCD

Enables ArgoCD to render kubernetes manifests using `cue`.

It supports `cue eval` and `cue cmd` and a sub-set of the available options for these sub-commands.


## Installation

You can install the CMP using the provided container image and plugin configuration

In the following section we provide snippets to apply the provided `Deployment` patch to
install `argocd-cmp-cuelang`. Please be aware that we assume that ArgoCD has been installed
into the `argocd` namespace, and the name of the ArgoCD Repo Server deployment is
`argocd-repo-server`; should this **not** be the case, you will need to update
the snippets accordingly.

We provide two separate installation patches for the side-car:

- Using the baked-in plugin.yaml from the container image
- Using a separate configMap for the plugin.yaml and mounting it into the side-car

Both patches use the `argocd-cmp-cuelang` container image by default. Customization is
of course entirely possible, but at your own risk.

Generate the patch using the baked-in plugin.yaml as follows:

```shell
> cue cmd patch github.com/deepbrook/argocd-cmp-cuelang/config@v0.0.13 > patch.yaml
```

If you'd like to use a separate configMap only requires `-t cm=true`:

```shell
> cue cmd patch github.com/deepbrook/argocd-cmp-cuelang/config@v0.0.13 -t cm=true > patch.yaml
```

Inspect and apply the patch

```
> cat patch.yaml  # Inspect the patch
> kubectl patch deployment --namespace=argocd argocd-repo-server --patch-file=patch.yaml
```

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

Regardless of your choice, make sure to set `CUE_CACHE_DIR` to an existing directory **within** the image. The plugin isn't granted write access to the working directory. Have a look at our [Containerfile](./Containerfile) to see how we solve this.

## Usage

The plugin can be used as soon as a `.cue` file is detected in the source directory.

```
spec:
  source:
    plugin:
      name: cuelang-v0.0.13
```

This will invoke `cue eval -e manifests --out=text` in your source's `path` directory.

This behaviour can be customized, of course. See the next sections for details on how.

### Common parameters

Whether a parameter is used is dependent on the value of the `cue-command` parameters. However, the following parameters are **always**
applied and honored:

- `package`: declares the CUE package you want to evaluate or run a workflow from. This can be a package in your repository, or a module from a registry. It defaults to the `source` directory, and `argocd-cmp-cuelang` always assumes there is only **one** package in this directory.

- `tags`: Allows declaring an `array` of tags you want pass to the cue command. This defaults to an empty array.

When declaring a relative path to a package using the `package` parameter, please note that `cue` is run
in the application source's `path` (accessed via the environment variable `ARGOCD_APP_SOURCE_PATH` by the plugin).


### Generating Manifests with `cue eval`

By default, the cmp will invoke `cue eval` on the Application's `spec.source.path`, and expect an encoded
string (YAML or JSON) at the expression `manifests`, since we're using the `text` output mode during evaluation.

You can customize these values by setting the following parameters:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: expressions
          array: ["yourExpression"]  # You may declare multiple expressions; overrides 'manifests'
        - name: output
          string: "yaml"  # May be one of "yaml", "json" or "text", default "text".
```

<details><summary>Why not `--out=yaml|json`? Why use `-e/--expression`?</summary>

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
</details>



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

The default CUE workflow invoked is `build`. This can be modified using the following parameter:

```yaml
spec:
  source:
    plugin:
      parameters:
        - name: workflow
          string: "your-workflow-command-name"
```



[per the official docs]: https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#installing-a-config-management-plugin