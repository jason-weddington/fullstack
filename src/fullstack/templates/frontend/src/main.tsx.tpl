import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import '@fontsource/roboto/300.css'
import '@fontsource/roboto/400.css'
import '@fontsource/roboto/500.css'
import '@fontsource/roboto/700.css'
import { ThemeProvider } from './contexts/ThemeContext'
##if AUTH
import { AuthProvider } from './contexts/AuthContext'
##endif
import App from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
##if AUTH
      <AuthProvider>
        <ThemeProvider>
          <App />
        </ThemeProvider>
      </AuthProvider>
##else
      <ThemeProvider>
        <App />
      </ThemeProvider>
##endif
    </BrowserRouter>
  </StrictMode>,
)
