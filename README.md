# Infrastructure as Code Make Framework

This framework is an attempt to create a convenient way to manage Infrastructure as Code with low barrier of entry for the Runner.

The idea is to use [GNU Make](https://www.gnu.org/software/make/) as a vehicle for wrapping the complexity and presenting a nice Runner Experience. 

This way, a coherent set of commands can be used locally or on the CI, as simple as:
```shell script
make deploy # One-stop command that deploys everything from scratch in a right order. Infra, Applications, etc.
```
Or
```shell script
make infra # Deploys the whole infrastructure (Terraform)
make api # Builds a Docker image, Pushes it to Docker registry and deploys ECS service
make secrets # Pushes secrets to SSM
```
Or
```shell script
make tunnel # Creates an SSH tunnel via bastion host
```

# Quickstart
This `init` onliner will download and configure icmk in your directory. (Defaults to .infra/icmk, customizable).
```shell script
make init -f $(curl -Ls https://hzl.xyz/icmk > $TMPDIR/icmk.mk && echo "$TMPDIR/icmk.mk")
```

## Populate sample config
This will create the following:
- Sample `Makefile`, which you can (and should) customize
- Sample .envrc (which you can use with [direnv](https://github.com/direnv/direnv))
- Sample Terraform environment structure under `.infra/env/testnut` which has a demo of bastion host and ssh tunnel. It forwards `localhost:222` to `bastion:22`. See `make tunnel.up` and `make tunnel.down`. In order to use make tunnel.up, Terraform config must be applied at least once (locally or via CI/CD).
- Sample secrets directory that is used to push secrets to SSM via `make secrets`. Make sure to keep your `secrets/*.json` files out of git. 

This won't create:
- Anything else.

```shell script
make examples.simple
```

# Whats Wrong With Shell Scripts?
Shell scripts do the job, but eventually they loose the coherency by turning into bash spaghetti. Makefiles are declarative and have ability to have dependencies. Also, GNU Make can be modular, which allows to build good Runner Experience with abstractions. There is more, but if this is not enough, feel free to submit a Github Issue with any questions or concerns.

## Ensure your Terraform has required outputs
This framework heavily relies on Terraform to get different values. It stores them in `output.json` and then reads them as needed. 

# Features
Currently, main features include
- Terraform
- AWS
- Docker
- ECS
- SSH Tunnel

# Dependencies
The only dependencies you'd need:
- GNU Make
- Git
- Docker

# Disclaimer
This framework is inspired by the principles of delivering a good Runner Experience. It is provided as-is.

\*This is nothing close to a complete framework: lots of features are still missing, naming and structuring can be improved. Even though it works, use it on your own risk. PRs are welcome! 

