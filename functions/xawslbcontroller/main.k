import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.io.crossplane.helm.v1beta1 as helmv1beta1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
import json
import iam_policy


oxr = option("params").oxr # observed composite resource
_ocds = option("params").ocds # observed composed resources
_dxr = option("params").dxr # desired composite resource
dcds = option("params").dcds # desired composed resources

_metadata = lambda name: str -> any {
    {
        name = name
        annotations = { "krm.kcl.dev/composition-resource-name" = name }
    }
}

# Extract parameters from XR
_region = oxr.spec?.parameters?.region or "us-west-2"
_clusterName = oxr.spec?.parameters?.clusterName or None
_clusterNameRef = oxr.spec?.parameters?.clusterNameRef or None
_clusterNameSelector = oxr.spec?.parameters?.clusterNameSelector or None
_deletionPolicy = oxr.spec?.parameters?.deletionPolicy or "Delete"
_providerConfigName = oxr.spec?.parameters?.providerConfigName or None
_helmProviderConfigName = oxr.spec?.parameters?.helm?.providerConfigName or None
_helmChartVersion = oxr.spec?.parameters?.helm?.chart?.version or "1.8.3"

# Get cluster name from observed XPodIdentity (only available after it's created)
_observedClusterName = _ocds?.podidentity?.Resource?.status?.podIdentity?.clusterName

# Convert imported KCL policy data back to JSON string
_awsLbControllerPolicy = json.encode(iam_policy.aws_lb_controller_policy)

_items = [
    # Pod Identity for AWS Load Balancer Controller
    awsv1alpha1.XPodIdentity {
        metadata: _metadata("podidentity")
        spec: {
            parameters: {
                region: _region
                serviceAccount: {
                    name: "aws-load-balancer-controller"
                    namespace: "kube-system"
                }
                inlinePolicy: [
                    {
                        name: "aws-lb-controller-policy"
                        policy: _awsLbControllerPolicy
                    }
                ]
                if _clusterName:
                    clusterName: _clusterName
                if _clusterNameRef:
                    clusterNameRef: _clusterNameRef
                if _clusterNameSelector:
                    clusterNameSelector: _clusterNameSelector
                if _deletionPolicy:
                    deletionPolicy: _deletionPolicy
                if _providerConfigName:
                    providerConfigName: _providerConfigName
            }
        }
    },

    # Helm Release for AWS Load Balancer Controller
    helmv1beta1.Release {
        metadata: _metadata("helmrelease")
        spec: {
            forProvider: {
                chart: {
                    name: "aws-load-balancer-controller"
                    repository: "https://aws.github.io/eks-charts"
                    version: _helmChartVersion
                }
                namespace: "kube-system"
                values: {
                    serviceAccount: {
                        name: "aws-load-balancer-controller"
                    }
                    # Start with 0 replicas, will be patched to 2 when IAM role is ready
                    replicaCount: 0
                    # Only set clusterName if available from observed XPodIdentity
                    if _observedClusterName:
                        clusterName = _observedClusterName
                }
            }
            rollbackLimit: 3
            if _deletionPolicy:
                deletionPolicy: _deletionPolicy
            if _helmProviderConfigName:
                providerConfigRef: {
                    name: _helmProviderConfigName
                }
        }
    },

    # Usage resource to ensure proper deletion ordering with EKS clusters
    {
        apiVersion: "apiextensions.crossplane.io/v1alpha1"
        kind: "Usage"
        metadata: _metadata("usage-xeks-by-awslbcontroller")
        spec: {
            replayDeletion: True
            by: {
                apiVersion: "helm.crossplane.io/v1beta1"
                kind: "Release"
                resourceSelector: {
                    matchControllerRef: True
                }
            }
            of: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "XEKS"
                resourceSelector: {
                    matchLabels: {
                        "platform.upbound.io/deletion-ordering": "enabled"
                    }
                }
            }
        }
    }
]

items = _items
