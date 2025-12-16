package build

import (
    "tool/exec"
    "tool/file"

)

release: string @tag(version)

command: build: {

    prepareVersion: file.Create & {
        filename: "src/version.cue"
        contents: """
        // This file is auto-generated - do not edit!
        package plugin

        version: "\(release)"
        """
    }

    loadConfig: exec.Run & {
        cmd: ["cue", "eval", "./config/configMap.cue", "-e", "cm_data", "--out", "yaml"]
        dir: "src/"
        stdout: string
    }

    prepareConfig: file.Create & {
        filename: "plugin.yaml"
        contents: loadConfig.stdout
    }

    commit: exec.Run & {
        $after: [prepareVersion, prepareConfig]
        cmd: ["git", "commit", "-m", "chore: Release Module Version \(release)", "src/version.cue", "plugin.yaml"]
    }

    tag: exec.Run & {
        $after: [commit]
        cmd: ["git", "tag", "-s", "-m", "argocd-cmp-cuelang-\(release)", release]
    }

    // cue_version: exec.Run & {
    //     cmd: ["cue", "eval", "./src/cue.mod/module.cue", "-e", "language.version", "--out", "yaml"]
    //     stdout: string
    // }

    // container: exec.Run & {
    //     $after: [prepare, cue_version, tag]
    //     cmd: [
    //         "podman", "build", ".",
    //         "--tag", "ghcr.io/deepbrook/argocd-cmp-cuelang:\(mod_version)",
    //         "--build-arg", "CUE_VERSION=\(strings.Trim(cue_version.stdout, "v\n"))"]
    // }

    // push: exec.Run & {
    //     $after: [container]
    //     cmd: [
    //         "podman", "push",
    //         "ghcr.io/deepbrook/argocd-cmp-cuelang:\(mod_version)",
    //         ]
    // }
}