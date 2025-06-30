# KCL Schema definitions for EKS cluster configuration

schema EKSClusterSpec:
    """EKS Cluster specification schema"""
    clusterName: str
    region: str = "us-west-2"
    version: str = "1.31"
    nodeGroupConfig: EKSNodeGroupConfig
    networking: EKSNetworkingConfig
    tags?: {str: str}

schema EKSNodeGroupConfig:
    """EKS Node Group configuration schema"""
    instanceTypes: [str] = ["t3.medium"]
    minSize: int = 1
    maxSize: int = 10
    desiredSize: int = 3
    diskSize: int = 20
    capacityType: str = "ON_DEMAND"

schema EKSNetworkingConfig:
    """EKS Networking configuration schema"""
    vpcCidr: str = "10.0.0.0/16"
    enablePrivateEndpoint: bool = True
    enablePublicEndpoint: bool = True
    subnetCidrs: EKSSubnetCidrs = EKSSubnetCidrs {}

schema EKSSubnetCidrs:
    """Subnet CIDR configuration"""
    publicSubnets: [str] = ["10.0.1.0/24", "10.0.2.0/24"]
    privateSubnets: [str] = ["10.0.10.0/24", "10.0.20.0/24"]

schema AWSResource:
    """Base AWS resource schema"""
    apiVersion: str
    kind: str
    metadata: ResourceMetadata
    spec: {str: any}

schema ResourceMetadata:
    """Kubernetes resource metadata"""
    name: str
    labels?: {str: str}
    annotations?: {str: str}

schema CrossplaneComposition:
    """Crossplane Composition schema"""
    apiVersion: str = "apiextensions.crossplane.io/v1"
    kind: str = "Composition"
    metadata: ResourceMetadata
    spec: CompositionSpec

schema CompositionSpec:
    """Composition specification"""
    compositeTypeRef: CompositeTypeRef
    mode: str = "Pipeline"
    pipeline: [PipelineStep]

schema CompositeTypeRef:
    """Composite type reference"""
    apiVersion: str
    kind: str

schema PipelineStep:
    """Pipeline step configuration"""
    step: str
    functionRef: FunctionRef
    input?: {str: any}

schema FunctionRef:
    """Function reference"""
    name: str
