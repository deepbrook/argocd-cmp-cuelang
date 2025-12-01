package build

import "deepbrook.io/argocd-cmp-cuelang/config"
import "tool/cli"
import "encoding/yaml"

command: "eval-cmp": out: cli.Print & {text: yaml.Marshal(config.eval) }
command: "cmd-cmp": out: cli.Print & {text: yaml.Marshal(config.cmd) }

