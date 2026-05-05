import { useState, useEffect, useCallback, type ReactNode } from 'react'
import { Box, useTheme, useMediaQuery } from '@mui/material'
import FavoriteIcon from '@mui/icons-material/Favorite'
import FavoriteBorderIcon from '@mui/icons-material/FavoriteBorder'
import CloseIcon from '@mui/icons-material/Close'
import Lightbox from 'yet-another-react-lightbox'
import 'yet-another-react-lightbox/styles.css'

interface AppLightboxProps {
  open: boolean
  index: number
  slides: { src: string }[]
  onClose: () => void
  onView: (event: { index: number }) => void
  /** Custom slide renderer (e.g. AuthenticatedPreview for queue photos) */
  renderSlide?: (slide: { src: string }) => ReactNode
  /** Info bar overlay rendered at the bottom of the lightbox */
  infoBar?: ReactNode
  /** If provided, pressing F triggers this callback and shows a fave flash */
  onKeyF?: () => void
  /** Whether the current photo is faved (controls flash icon) */
  isFaved?: boolean
  /** If provided, pressing X triggers this callback and shows a dismiss flash */
  onKeyX?: () => void
  /** If provided, pressing G triggers this callback (skip, no flash) */
  onKeyG?: () => void
}

type FlashKind = 'fave' | 'unfave' | 'dismiss' | null

export default function AppLightbox({
  open,
  index,
  slides,
  onClose,
  onView,
  renderSlide,
  infoBar,
  onKeyF,
  isFaved,
  onKeyX,
  onKeyG,
}: AppLightboxProps) {
  const [flash, setFlash] = useState<FlashKind>(null)
  const [flashKey, setFlashKey] = useState(0)
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))

  // Clear flash after fade-out completes
  useEffect(() => {
    if (!flash) return
    const timer = setTimeout(() => setFlash(null), 600)
    return () => clearTimeout(timer)
  }, [flash])

  // Memoize so the effect dependency is stable
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        e.stopImmediatePropagation()
        onClose()
        return
      }
      if (onKeyF && (e.key === 'f' || e.key === 'F')) {
        setFlashKey((k) => k + 1)
        setFlash(isFaved ? 'unfave' : 'fave')
        onKeyF()
      }
      if (onKeyX && (e.key === 'x' || e.key === 'X')) {
        setFlashKey((k) => k + 1)
        setFlash('dismiss')
        onKeyX()
      }
      if (onKeyG && (e.key === 'g' || e.key === 'G')) {
        onKeyG()
      }
    },
    [onClose, onKeyF, isFaved, onKeyX, onKeyG],
  )

  useEffect(() => {
    if (!open) return
    document.addEventListener('keydown', handleKeyDown, true)
    return () => document.removeEventListener('keydown', handleKeyDown, true)
  }, [open, handleKeyDown])

  return (
    <>
      <Lightbox
        open={open}
        close={onClose}
        index={index}
        slides={slides}
        animation={{ fade: 0, swipe: isMobile ? 250 : 0 }}
        controller={{ closeOnBackdropClick: true }}
        on={{ view: onView }}
        render={{
          ...(renderSlide ? { slide: ({ slide }) => <>{renderSlide(slide)}</> } : {}),
          ...(isMobile ? { buttonPrev: () => null, buttonNext: () => null } : {}),
        }}
      />
      {open && infoBar}
      {flash && open && (
        <Box
          key={`${flash}-${flashKey}`}
          sx={{
            position: 'fixed',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            zIndex: 10001,
            pointerEvents: 'none',
            opacity: 1,
            animation: 'actionFlashOut 0.6s ease-out forwards',
            '@keyframes actionFlashOut': {
              '0%': { opacity: 0.85 },
              '100%': { opacity: 0 },
            },
          }}
        >
          {flash === 'fave' ? (
            <FavoriteIcon sx={{ fontSize: 80, color: 'error.main' }} />
          ) : flash === 'unfave' ? (
            <FavoriteBorderIcon sx={{ fontSize: 80, color: 'grey.400' }} />
          ) : (
            <CloseIcon sx={{ fontSize: 80, color: 'error.main' }} />
          )}
        </Box>
      )}
    </>
  )
}
