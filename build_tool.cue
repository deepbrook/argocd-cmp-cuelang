package build

import (
    "tool/exec"
    "tool/file"
    "strings"
)

version_tag: string @tag(version)

command: "publish": {
    prepareVersion: file.Create & {
        filename: "src/version.cue"
        contents: """
        // This file is auto-generated - do not edit!
        package plugin

        version: "\(version_tag)"
        """
    }

    loadReadmeTemplate: file.Read & {
        filename: "tools/README.md.template"
        contents: string
    }

    updateReadme: file.Create & {
        filename: "README.md"
        contents: strings.Replace(loadReadmeTemplate.contents, "<VERSION>", version_tag, -1)
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
        cmd: ["git", "commit", "-m", "chore: Release Module Version \(version_tag)", "src/version.cue", "plugin.yaml", "README.md"]
    }

    tag: exec.Run & {
        $after: [commit]
        cmd: ["git", "tag", "-a", "-m", "argocd-cmp-cuelang-\(version_tag)", version_tag]
    }

    publish: exec.Run & {
        $after: [commit]
        dir: "src/"
        cmd: ["cue", "mod", "publish", version_tag]
    }

    push: exec.Run & {
        $after: [tag]
        cmd: ["git", "push", "origin", "tag", version_tag]
    }

    cue_version: exec.Run & {
        cmd: ["cue", "eval", "./src/cue.mod/module.cue", "-e", "language.version", "--out", "yaml"]
        stdout: string
    }

    build_image: exec.Run & {
        $after: [cue_version]
        cmd: [
            "podman", "build", ".",
            "--tag", "ghcr.io/deepbrook/argocd-cmp-cuelang:\(version_tag)",
            "--build-arg", "CUE_VERSION=\(strings.Trim(cue_version.stdout, "v\n"))"]
    }

    push_image: exec.Run & {
        $after: [build_image]
        cmd: [
            "podman", "push",
            "ghcr.io/deepbrook/argocd-cmp-cuelang:\(version_tag)",
        ]
    }
}