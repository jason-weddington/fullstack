import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
##if AUTH
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
##endif
import Dashboard from './pages/Dashboard'
import Settings from './pages/Settings'

export default function App() {
  return (
    <Routes>
##if AUTH
      <Route path="/login" element={<Login />} />
      <Route
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Route>
##else
      <Route element={<Layout />}>
        <Route path="/" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Route>
##endif
    </Routes>
  )
}
