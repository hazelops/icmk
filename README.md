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

# Whats Wrong With Shell Scripts?
Shell scripts do the job, but eventually they loose the coherency by turning into bash spaghetti. Makefiles are declarative and have ability to have dependencies. Also, GNU Make can be modular, which allows to build good Runner Experience with abstractions. There is more, but if this is not enough, feel free to submit a Github Issue with any questions or concerns.
 
# Quickstart
Clone or as a submodule, then include from your local Makefile. _(See examples)_

### Add as a submodule
```
git submodule add https://github.com/hazelops/icmk.git .infra/icmk
```

### Include makiac in your local Makefile
```makefile
include .infra/icmk/*.mk
```

### Ensure your Terraform has required outputs
This framework heavily relies on Terraform to get different values. It stores them in `output.json` and then reads them as needed. 

Additional options to store `output.json` in SSM or Parameter Store or s3 bucket are not implemented yet (which will help with user permissions)

# Features
Currently, main features include
- Terraform
- AWS
- Docker
- ECS
- SSH Tunnel

# Dependencies
The only two dependencies that you need are *:
- GNU Make
- Docker

# Disclaimer
This framework is inspired by the principles of delivering a good Runner Experience. It is provided as-is.

\*This is nothing close to a complete framework: lots of features are still missing, naming and structuring can be improved. Even though it works, use it on your own risk.
