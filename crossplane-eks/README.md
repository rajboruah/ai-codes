# Crossplane EKS Cluster Configuration

This project contains Crossplane scripts written in KCL (KusionStack Configuration Language) to create and manage Amazon EKS clusters.

## Structure

- `compositions/` - Crossplane Composition definitions
- `composite-resource-definitions/` - XRD (Composite Resource Definition) files
- `functions/` - KCL pipeline functions
- `examples/` - Example usage and test configurations
- `schemas/` - KCL schema definitions

## Prerequisites

1. Kubernetes cluster with Crossplane installed
2. AWS Provider for Crossplane configured
3. KCL runtime and tools installed

## Quick Start

1. Apply the Composite Resource Definitions:
   ```bash
   kubectl apply -f composite-resource-definitions/
   ```

2. Apply the Compositions:
   ```bash
   kubectl apply -f compositions/
   ```

3. Create an EKS cluster using the example:
   ```bash
   kubectl apply -f examples/eks-cluster-example.yaml
   ```

## Features

- Complete EKS cluster setup with node groups
- VPC and networking configuration
- Security groups and IAM roles
- Configurable cluster parameters
- KCL-based composition functions for flexible configuration
