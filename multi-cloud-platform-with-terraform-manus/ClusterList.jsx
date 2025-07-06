import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { 
  Cloud, 
  Server, 
  MapPin, 
  Calendar, 
  Trash2, 
  RefreshCw, 
  Plus,
  ExternalLink
} from 'lucide-react'

const STATUS_COLORS = {
  pending: 'bg-yellow-100 text-yellow-800',
  creating: 'bg-blue-100 text-blue-800',
  running: 'bg-green-100 text-green-800',
  failed: 'bg-red-100 text-red-800',
  deleting: 'bg-orange-100 text-orange-800',
  deleted: 'bg-gray-100 text-gray-800',
}

const CLOUD_ICONS = {
  aws: '🟠',
  azure: '🔵',
}

export function ClusterList({ user, onCreateCluster, onLogout }) {
  const [clusters, setClusters] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const fetchClusters = async () => {
    try {
      const response = await fetch('/api/clusters', {
        credentials: 'include',
      })

      if (response.ok) {
        const data = await response.json()
        setClusters(data)
      } else {
        setError('Failed to fetch clusters')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchClusters()
    // Poll for updates every 10 seconds
    const interval = setInterval(fetchClusters, 10000)
    return () => clearInterval(interval)
  }, [])

  const handleDeleteCluster = async (clusterId) => {
    if (!confirm('Are you sure you want to delete this cluster?')) {
      return
    }

    try {
      const response = await fetch(`/api/clusters/${clusterId}`, {
        method: 'DELETE',
        credentials: 'include',
      })

      if (response.ok) {
        fetchClusters()
      } else {
        const data = await response.json()
        alert(data.error || 'Failed to delete cluster')
      }
    } catch (err) {
      alert('Network error. Please try again.')
    }
  }

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
        credentials: 'include',
      })
      onLogout()
    } catch (err) {
      console.error('Logout error:', err)
      onLogout()
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p>Loading clusters...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Multi-Cloud Kubernetes Platform
              </h1>
              <p className="text-sm text-gray-600">
                Welcome back, {user.username} ({user.role})
              </p>
            </div>
            <div className="flex gap-3">
              <Button onClick={onCreateCluster} className="flex items-center gap-2">
                <Plus className="h-4 w-4" />
                Create Cluster
              </Button>
              <Button variant="outline" onClick={handleLogout}>
                Logout
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {error && (
          <Alert variant="destructive" className="mb-6">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {clusters.length === 0 ? (
          <Card className="text-center py-12">
            <CardContent>
              <Cloud className="h-16 w-16 mx-auto mb-4 text-gray-400" />
              <h3 className="text-lg font-semibold mb-2">No clusters yet</h3>
              <p className="text-gray-600 mb-6">
                Create your first Kubernetes cluster to get started
              </p>
              <Button onClick={onCreateCluster} className="flex items-center gap-2 mx-auto">
                <Plus className="h-4 w-4" />
                Create Your First Cluster
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {clusters.map((cluster) => (
              <Card key={cluster.id} className="hover:shadow-lg transition-shadow">
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-lg flex items-center gap-2">
                        <span>{CLOUD_ICONS[cluster.cloud_provider]}</span>
                        {cluster.name}
                      </CardTitle>
                      <CardDescription className="flex items-center gap-1 mt-1">
                        <MapPin className="h-3 w-3" />
                        {cluster.region}
                      </CardDescription>
                    </div>
                    <Badge className={STATUS_COLORS[cluster.status] || STATUS_COLORS.pending}>
                      {cluster.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-gray-600">Provider</p>
                      <p className="font-medium capitalize">{cluster.cloud_provider}</p>
                    </div>
                    <div>
                      <p className="text-gray-600">K8s Version</p>
                      <p className="font-medium">{cluster.kubernetes_version}</p>
                    </div>
                    <div>
                      <p className="text-gray-600">Nodes</p>
                      <p className="font-medium flex items-center gap-1">
                        <Server className="h-3 w-3" />
                        {cluster.node_count}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-600">Instance Type</p>
                      <p className="font-medium">{cluster.instance_type}</p>
                    </div>
                  </div>
                  
                  <div className="text-xs text-gray-500 flex items-center gap-1">
                    <Calendar className="h-3 w-3" />
                    Created {new Date(cluster.created_at).toLocaleDateString()}
                  </div>

                  {cluster.cluster_endpoint && (
                    <div className="pt-2">
                      <Button variant="outline" size="sm" className="w-full flex items-center gap-2">
                        <ExternalLink className="h-3 w-3" />
                        View Cluster
                      </Button>
                    </div>
                  )}

                  {user.role === 'admin' && cluster.status !== 'deleting' && cluster.status !== 'deleted' && (
                    <div className="pt-2">
                      <Button
                        variant="destructive"
                        size="sm"
                        className="w-full flex items-center gap-2"
                        onClick={() => handleDeleteCluster(cluster.id)}
                      >
                        <Trash2 className="h-3 w-3" />
                        Delete Cluster
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

