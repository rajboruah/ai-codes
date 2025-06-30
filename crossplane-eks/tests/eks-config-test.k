# Crossplane EKS Configuration Tests

import "functions/main-function.k" as main
import "schemas/eks-schemas.k" as schemas

# Test basic EKS cluster configuration
test_basic_eks_config = lambda {
    config = {
        clusterName = "test-cluster"
        region = "us-west-2"
        version = "1.31"
    }
    
    spec = main.createEKSClusterSpec(config)
    
    # Validate the spec
    assert spec.clusterName == "test-cluster"
    assert spec.region == "us-west-2"
    assert spec.version == "1.31"
    assert spec.nodeGroupConfig.minSize == 1
    assert spec.nodeGroupConfig.maxSize == 10
    assert spec.nodeGroupConfig.desiredSize == 3
    
    True
}

# Test node group configuration
test_node_group_config = lambda {
    config = {
        clusterName = "test-cluster"
        nodeGroupConfig = {
            instanceTypes = ["m5.large"]
            minSize = 2
            maxSize = 20
            desiredSize = 5
            diskSize = 100
        }
    }
    
    spec = main.createEKSClusterSpec(config)
    
    # Validate node group config
    assert spec.nodeGroupConfig.instanceTypes == ["m5.large"]
    assert spec.nodeGroupConfig.minSize == 2
    assert spec.nodeGroupConfig.maxSize == 20
    assert spec.nodeGroupConfig.desiredSize == 5
    assert spec.nodeGroupConfig.diskSize == 100
    
    True
}

# Test networking configuration
test_networking_config = lambda {
    config = {
        clusterName = "test-cluster"
        networking = {
            vpcCidr = "10.1.0.0/16"
            enablePrivateEndpoint = True
            enablePublicEndpoint = False
            subnetCidrs = {
                publicSubnets = ["10.1.1.0/24", "10.1.2.0/24"]
                privateSubnets = ["10.1.10.0/24", "10.1.20.0/24"]
            }
        }
    }
    
    spec = main.createEKSClusterSpec(config)
    
    # Validate networking config
    assert spec.networking.vpcCidr == "10.1.0.0/16"
    assert spec.networking.enablePrivateEndpoint == True
    assert spec.networking.enablePublicEndpoint == False
    assert len(spec.networking.subnetCidrs.publicSubnets) == 2
    assert len(spec.networking.subnetCidrs.privateSubnets) == 2
    
    True
}

# Test configuration validation
test_config_validation = lambda {
    # Test invalid configuration
    invalidConfig = schemas.EKSClusterSpec {
        clusterName = ""  # Invalid: empty name
        region = "us-west-2"
        nodeGroupConfig = schemas.EKSNodeGroupConfig {
            minSize = 5
            maxSize = 2  # Invalid: max < min
            desiredSize = 10  # Invalid: desired > max
        }
    }
    
    # This should fail validation
    try:
        main.validateEKSConfig(invalidConfig)
        # If we reach here, validation didn't work
        False
    except:
        # Validation caught the error as expected
        True
}

# Test resource generation
test_resource_generation = lambda {
    config = {
        clusterName = "test-cluster"
        region = "us-west-2"
    }
    
    spec = main.createEKSClusterSpec(config)
    resources = main.generateEKSCluster(spec)
    
    # Should generate multiple resources
    assert len(resources) > 0
    
    # Check that we have different types of resources
    resourceKinds = [resource.kind for resource in resources]
    assert "VPC" in resourceKinds
    assert "Role" in resourceKinds
    assert "SecurityGroup" in resourceKinds
    assert "Cluster" in resourceKinds
    
    True
}

# Run all tests
test_results = {
    "basic_config": test_basic_eks_config()
    "node_group_config": test_node_group_config()
    "networking_config": test_networking_config()
    "config_validation": test_config_validation()
    "resource_generation": test_resource_generation()
}

# Print test results
print("🧪 Test Results:")
for test_name, result in test_results:
    status = "✅ PASS" if result else "❌ FAIL"
    print(f"  {test_name}: {status}")

# Overall result
all_passed = all([result for _, result in test_results])
overall_status = "✅ ALL TESTS PASSED" if all_passed else "❌ SOME TESTS FAILED"
print(f"\n{overall_status}")
