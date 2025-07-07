import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Loader2, Plus } from 'lucide-react'

const AWS_REGIONS = [
  { value: 'us-east-1', label: 'US East (N. Virginia)' },
  { value: 'us-west-2', label: 'US West (Oregon)' },
  { value: 'eu-west-1', label: 'Europe (Ireland)' },
  { value: 'ap-southeast-1', label: 'Asia Pacific (Singapore)' },
]

const AZURE_REGIONS = [
  { value: 'eastus', label: 'East US' },
  { value: 'westus2', label: 'West US 2' },
  { value: 'westeurope', label: 'West Europe' },
  { value: 'southeastasia', label: 'Southeast Asia' },
]

const AWS_INSTANCE_TYPES = [
  { value: 't3.medium', label: 't3.medium (2 vCPU, 4 GB RAM)' },
  { value: 't3.large', label: 't3.large (2 vCPU, 8 GB RAM)' },
  { value: 'm5.large', label: 'm5.large (2 vCPU, 8 GB RAM)' },
  { value: 'm5.xlarge', label: 'm5.xlarge (4 vCPU, 16 GB RAM)' },
]

const AZURE_VM_SIZES = [
  { value: 'Standard_DS2_v2', label: 'Standard_DS2_v2 (2 vCPU, 7 GB RAM)' },
  { value: 'Standard_DS3_v2', label: 'Standard_DS3_v2 (4 vCPU, 14 GB RAM)' },
  { value: 'Standard_D4s_v3', label: 'Standard_D4s_v3 (4 vCPU, 16 GB RAM)' },
]

const KUBERNETES_VERSIONS = [
  { value: '1.28', label: 'Kubernetes 1.28' },
  { value: '1.29', label: 'Kubernetes 1.29' },
  { value: '1.30', label: 'Kubernetes 1.30' },
]

export function ClusterForm({ onClusterCreated, onCancel }) {
  const [formData, setFormData] = useState({
    name: '',
    cloud_provider: '',
    region: '',
    kubernetes_version: '',
    node_count: 2,
    instance_type: '',
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const response = await fetch('/api/clusters', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify(formData),
      })

      const data = await response.json()

      if (response.ok) {
        onClusterCreated(data)
      } else {
        setError(data.error || 'Failed to create cluster')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const getRegions = () => {
    return formData.cloud_provider === 'aws' ? AWS_REGIONS : AZURE_REGIONS
  }

  const getInstanceTypes = () => {
    return formData.cloud_provider === 'aws' ? AWS_INSTANCE_TYPES : AZURE_VM_SIZES
  }

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Plus className="h-5 w-5" />
          Create New Kubernetes Cluster
        </CardTitle>
        <CardDescription>
          Configure your Kubernetes cluster for deployment on AWS or Azure
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="name">Cluster Name</Label>
              <Input
                id="name"
                placeholder="my-k8s-cluster"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="cloud_provider">Cloud Provider</Label>
              <Select
                value={formData.cloud_provider}
                onValueChange={(value) => setFormData({ ...formData, cloud_provider: value, region: '', instance_type: '' })}
                required
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select cloud provider" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="aws">Amazon Web Services (AWS)</SelectItem>
                  <SelectItem value="azure">Microsoft Azure</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="region">Region</Label>
              <Select
                value={formData.region}
                onValueChange={(value) => setFormData({ ...formData, region: value })}
                disabled={!formData.cloud_provider}
                required
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select region" />
                </SelectTrigger>
                <SelectContent>
                  {getRegions().map((region) => (
                    <SelectItem key={region.value} value={region.value}>
                      {region.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="kubernetes_version">Kubernetes Version</Label>
              <Select
                value={formData.kubernetes_version}
                onValueChange={(value) => setFormData({ ...formData, kubernetes_version: value })}
                required
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select version" />
                </SelectTrigger>
                <SelectContent>
                  {KUBERNETES_VERSIONS.map((version) => (
                    <SelectItem key={version.value} value={version.value}>
                      {version.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="node_count">Node Count</Label>
              <Input
                id="node_count"
                type="number"
                min="1"
                max="10"
                value={formData.node_count}
                onChange={(e) => setFormData({ ...formData, node_count: parseInt(e.target.value) })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="instance_type">Instance Type</Label>
              <Select
                value={formData.instance_type}
                onValueChange={(value) => setFormData({ ...formData, instance_type: value })}
                disabled={!formData.cloud_provider}
                required
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select instance type" />
                </SelectTrigger>
                <SelectContent>
                  {getInstanceTypes().map((type) => (
                    <SelectItem key={type.value} value={type.value}>
                      {type.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {error && (
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <div className="flex gap-3 pt-4">
            <Button type="submit" disabled={loading} className="flex-1">
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Creating Cluster...
                </>
              ) : (
                'Create Cluster'
              )}
            </Button>
            <Button type="button" variant="outline" onClick={onCancel}>
              Cancel
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}

