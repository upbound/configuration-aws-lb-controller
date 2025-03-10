# AWS Load Balancer Controller Configuration


This repository contains a [Crossplane configuration](https://docs.crossplane.io/latest/concepts/packages/#configuration-packages), tailored for users establishing their initial control plane with [Upbound](https://cloud.upbound.io). This configuration deploys fully managed [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/) resources.

## Overview

The core components of a custom API in [Crossplane](https://docs.crossplane.io/latest/getting-started/introduction/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Implements the API by orchestrating a set of Crossplane managed resources.

In this specific configuration, the AWS Load Balancer Controller API contains:

- **Composition of the load balancer controller resources:** Configured in [/apis/composition.yaml](/apis/composition.yaml), it provisions the load-balancer controller helm chart and the necessary IAM Role with proper permissions.

This repository contains an Composite Resource (XR) file.

## Deployment

```shell
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-aws-network
spec:
  package: xpkg.upbound.io/upbound/configuration-aws-network:v0.15.0
```

## Testing

Run `make help.local` to get the up-to-date documentation for the testing
related targets, e.g

```shell
make help.local
e2e                            Run uptest together with all dependencies. Use `make e2e SKIP_DELETE=--skip-delete` to skip deletion of resources.
render                         Crossplane render
submodules                     Update the submodules, such as the common build scripts.
yamllint                       Static yamllint check
```

## Next steps

This repository serves as a foundational step. To enhance your control plane, consider:

1. create new API definitions in this same repo
2. editing the existing API definition to your needs


Upbound will automatically detect the commits you make in your repo and build the configuration package for you. To learn more about how to build APIs for your managed control planes in Upbound, read the guide on Upbound's docs.

# Using the make file
## render target
### Overview
`make render` target automates the rendering of Crossplane manifests using specified annotations within your YAML files.
The annotations guide the rendering process, specifying paths to composition, function, environment, and observe files.

### Annotations
The `make render` target relies on specific annotations in your YAML files to determine how to process each file.
The following annotations are supported:

**render.crossplane.io/composition-path**: Specifies the path to the composition file to be used in rendering.

**render.crossplane.io/function-path**: Specifies the path to the function file to be used in rendering.

**render.crossplane.io/environment-path** (optional): Specifies the path to the environment file. If not provided, the rendering will proceed without an environment.

**render.crossplane.io/observe-path** (optional): Specifies the path to the observe file. If not provided, the rendering will proceed without observation settings.

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: XNetwork
metadata:
  name: configuration-aws-network
  annotations:
    render.crossplane.io/composition-path: apis/gotpl/composition.yaml
    render.crossplane.io/function-path: examples/functions.yaml
spec:
  parameters:
    id: configuration-aws-network
    region: us-west-2
```
