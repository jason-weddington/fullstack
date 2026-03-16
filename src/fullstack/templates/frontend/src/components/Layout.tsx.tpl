import { useState } from 'react'
import { Outlet, useNavigate } from 'react-router-dom'
import {
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Box,
  Tooltip,
##if AUTH
  Avatar,
  Menu,
  MenuItem,
  ListItemIcon,
##endif
} from '@mui/material'
import MenuIcon from '@mui/icons-material/Menu'
import DarkModeIcon from '@mui/icons-material/DarkMode'
import LightModeIcon from '@mui/icons-material/LightMode'
import SettingsIcon from '@mui/icons-material/Settings'
##if AUTH
import LogoutIcon from '@mui/icons-material/Logout'
##endif
import AppsIcon from '@mui/icons-material/Apps'
import { useThemeMode } from '../contexts/ThemeContext'
##if AUTH
import { useAuth } from '../contexts/AuthContext'
##endif
import Sidebar from './Sidebar'

export default function Layout() {
  const { mode, toggleTheme } = useThemeMode()
##if AUTH
  const { user, logout } = useAuth()
##endif
  const navigate = useNavigate()
  const [sidebarOpen, setSidebarOpen] = useState(true)
##if AUTH
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)

  const displayName = user?.email ?? ''

  const handleLogout = () => {
    setAnchorEl(null)
    logout()
    navigate('/login')
  }
##endif

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <AppBar position="fixed" sx={{ zIndex: (t) => t.zIndex.drawer + 1 }}>
        <Toolbar>
          <IconButton
            color="inherit"
            edge="start"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            sx={{ mr: 1 }}
          >
            <MenuIcon />
          </IconButton>

          <Box
            onClick={() => navigate('/')}
            sx={{ display: 'flex', alignItems: 'center', cursor: 'pointer', flexGrow: 1 }}
          >
            <AppsIcon sx={{ mr: 1, color: 'primary.light' }} />
            <Typography
              variant="h6"
              component="div"
              sx={{ fontWeight: 700, letterSpacing: -0.5 }}
            >
              {{title}}
            </Typography>
          </Box>

          <Tooltip title={mode === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}>
            <IconButton color="inherit" onClick={toggleTheme} sx={{ mr: 1 }}>
              {mode === 'dark' ? <LightModeIcon /> : <DarkModeIcon />}
            </IconButton>
          </Tooltip>

##if NOAUTH
          <Tooltip title="Settings">
            <IconButton color="inherit" onClick={() => navigate('/settings')}>
              <SettingsIcon />
            </IconButton>
          </Tooltip>
##endif
##if AUTH
          <Tooltip title={displayName}>
            <IconButton onClick={(e) => setAnchorEl(e.currentTarget)} sx={{ p: 0 }}>
              <Avatar
                sx={{
                  width: 32,
                  height: 32,
                  bgcolor: 'primary.main',
                  fontSize: '0.875rem',
                  fontWeight: 600,
                }}
              >
                {displayName.charAt(0).toUpperCase()}
              </Avatar>
            </IconButton>
          </Tooltip>

          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={() => setAnchorEl(null)}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
            slotProps={{
              paper: {
                sx: { mt: 1, minWidth: 180 },
              },
            }}
          >
            <MenuItem
              onClick={() => {
                setAnchorEl(null)
                navigate('/settings')
              }}
            >
              <ListItemIcon>
                <SettingsIcon fontSize="small" />
              </ListItemIcon>
              Settings
            </MenuItem>
            <MenuItem onClick={handleLogout}>
              <ListItemIcon>
                <LogoutIcon fontSize="small" />
              </ListItemIcon>
              Sign Out
            </MenuItem>
          </Menu>
##endif
        </Toolbar>
      </AppBar>

      <Sidebar open={sidebarOpen} />

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          mt: '64px',
          p: 3,
          minHeight: 'calc(100vh - 64px)',
          transition: 'margin-left 225ms cubic-bezier(0, 0, 0.2, 1)',
        }}
      >
        <Outlet />
      </Box>
    </Box>
  )
}
