import {
  Box,
  Typography,
  Card,
  CardContent,
  Switch,
  FormControlLabel,
##if AUTH
  Divider,
##endif
} from '@mui/material'
import { useThemeMode } from '../contexts/ThemeContext'
##if AUTH
import { useAuth } from '../contexts/AuthContext'
##endif

export default function Settings() {
  const { mode, toggleTheme } = useThemeMode()
##if AUTH
  const { user } = useAuth()
##endif

  return (
    <Box sx={{ maxWidth: 600 }}>
      <Typography variant="h5" sx={{ mb: 3 }}>
        Settings
      </Typography>

      <Card sx={{ border: 1, borderColor: 'divider', mb: 3 }}>
        <CardContent>
          <Typography variant="overline" color="text.secondary" sx={{ fontWeight: 600 }}>
            Appearance
          </Typography>
          <Box sx={{ mt: 1 }}>
            <FormControlLabel
              control={
                <Switch checked={mode === 'dark'} onChange={toggleTheme} />
              }
              label="Dark mode"
            />
          </Box>
        </CardContent>
      </Card>
##if AUTH

      <Card sx={{ border: 1, borderColor: 'divider' }}>
        <CardContent>
          <Typography variant="overline" color="text.secondary" sx={{ fontWeight: 600 }}>
            Account
          </Typography>
          <Divider sx={{ my: 1 }} />
          <Typography variant="body2" color="text.secondary">
            Email
          </Typography>
          <Typography variant="body1">
            {user?.email}
          </Typography>
        </CardContent>
      </Card>
##endif
    </Box>
  )
}
