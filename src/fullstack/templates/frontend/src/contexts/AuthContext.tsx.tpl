import { createContext, useContext, useState, useCallback, useMemo, useEffect, type ReactNode } from 'react'
import { api } from '../api'
import type { UserResponse } from '../types'

interface AuthContextValue {
  isAuthenticated: boolean
  user: UserResponse | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  register: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserResponse | null>(() => {
    try {
      const raw = localStorage.getItem('{{name}}-user')
      return raw ? JSON.parse(raw) : null
    } catch {
      return null
    }
  })
  const [loading, setLoading] = useState(() => Boolean(localStorage.getItem('{{name}}-token')))

  useEffect(() => {
    const token = localStorage.getItem('{{name}}-token')
    if (!token) return
    let cancelled = false
    api.auth
      .me()
      .then((u) => {
        if (cancelled) return
        setUser(u)
        localStorage.setItem('{{name}}-user', JSON.stringify(u))
      })
      .catch(() => {
        if (cancelled) return
        localStorage.removeItem('{{name}}-token')
        localStorage.removeItem('{{name}}-user')
        setUser(null)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => { cancelled = true }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.auth.login(email, password)
    localStorage.setItem('{{name}}-token', res.token)
    localStorage.setItem('{{name}}-user', JSON.stringify(res.user))
    setUser(res.user)
  }, [])

  const register = useCallback(async (email: string, password: string) => {
    const res = await api.auth.register(email, password)
    localStorage.setItem('{{name}}-token', res.token)
    localStorage.setItem('{{name}}-user', JSON.stringify(res.user))
    setUser(res.user)
  }, [])

  const logout = useCallback(() => {
    api.auth.logout().catch(() => {})
    localStorage.removeItem('{{name}}-token')
    localStorage.removeItem('{{name}}-user')
    setUser(null)
  }, [])

  const value = useMemo(
    () => ({
      isAuthenticated: user !== null,
      user,
      loading,
      login,
      register,
      logout,
    }),
    [user, loading, login, register, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
