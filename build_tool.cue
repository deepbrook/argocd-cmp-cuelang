package build

import (
    "tool/exec"
    "strings"
    "github.com/deepbrook/argocd-cmp-cuelang:plugin"
)

mod_version: plugin.version

command: build: {
    cue_version: exec.Run & {
        cmd: ["cue", "eval", "./cue.mod/module.cue", "-e", "language.version", "--out", "yaml"]
        stdout: string
    }

    build_log: exec.Run & {
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