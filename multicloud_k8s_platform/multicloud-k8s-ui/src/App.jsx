import { useState, useEffect } from 'react'
import { LoginForm } from './components/LoginForm'
import { ClusterList } from './components/ClusterList'
import { ClusterForm } from './components/ClusterForm'
import './App.css'

function App() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showCreateForm, setShowCreateForm] = useState(false)

  useEffect(() => {
    // Check if user is already logged in
    const checkAuth = async () => {
      try {
        const response = await fetch('/api/auth/status', {
          credentials: 'include',
        })
        const data = await response.json()
        
        if (data.authenticated) {
          setUser(data.user)
        }
      } catch (err) {
        console.error('Auth check failed:', err)
      } finally {
        setLoading(false)
      }
    }

    checkAuth()
  }, [])

  const handleLogin = (userData) => {
    setUser(userData)
  }

  const handleLogout = () => {
    setUser(null)
  }

  const handleCreateCluster = () => {
    setShowCreateForm(true)
  }

  const handleClusterCreated = () => {
    setShowCreateForm(false)
    // The cluster list will automatically refresh
  }

  const handleCancelCreate = () => {
    setShowCreateForm(false)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p>Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return <LoginForm onLogin={handleLogin} />
  }

  if (showCreateForm) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-8">
        <ClusterForm 
          onClusterCreated={handleClusterCreated}
          onCancel={handleCancelCreate}
        />
      </div>
    )
  }

  return (
    <ClusterList 
      user={user}
      onCreateCluster={handleCreateCluster}
      onLogout={handleLogout}
    />
  )
}

export default App
