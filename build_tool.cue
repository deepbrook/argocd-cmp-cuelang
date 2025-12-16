package build

import (
    "tool/exec"
    "tool/file"
    "encoding/yaml"
    "strings"
    "github.com/deepbrook/argocd-cmp-cuelang:plugin"
    "github.com/deepbrook/argocd-cmp-cuelang/config"
)

mod_version: plugin.version

command: build: {
    cue_version: exec.Run & {
        cmd: ["cue", "eval", "./cue.mod/module.cue", "-e", "language.version", "--out", "yaml"]
        stdout: string
    }

    prepare: file.Create & {
        filename: "plugin.yaml"
        contents: yaml.Marshal(config.cm_data)
    }

    build_log: exec.Run & {
        $after: [prepare]
        cmd: [
            "podman", "build", ".",
            "--tag", "ghcr.io/deepbrook/argocd-cmp-cuelang:\(mod_version)",
            "--build-arg", "CUE_VERSION=\(strings.Trim(cue_version.stdout, "v\n"))"]
    }

    push: exec.Run & {
        $after: [build_log]
        cmd: [
            "podman", "push",
            "ghcr.io/deepbrook/argocd-cmp-cuelang:\(mod_version)",
            ]
    }
}