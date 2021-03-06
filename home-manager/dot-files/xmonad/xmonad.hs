import qualified Data.Map                         as M
import           Data.Monoid                      ((<>))
import           System.IO                        (hPutStrLn)

import qualified Graphics.X11.Types               as XT
import           XMonad                           (Layout, ManageHook,
                                                   X, XConfig (..), def,
                                                   mod4Mask, spawn,
                                                   xmonad, (.|.), (|||))
import           XMonad.Hooks.DynamicLog          (dynamicLogWithPP, xmobarColor, shorten, wrap, xmobarPP,
                                                   PP (ppOutput, ppCurrent, ppVisible, ppLayout, ppTitle))
import           XMonad.Hooks.EwmhDesktops        (ewmh, fullscreenEventHook)
import           XMonad.Hooks.ManageDocks         (avoidStruts, docks,
                                                   manageDocks)
import           XMonad.Hooks.ManageHelpers       (doFullFloat, isFullscreen)
import           XMonad.Layout.NoBorders          (smartBorders)
import           XMonad.Layout.ThreeColumns       (ThreeCol (ThreeColMid))
import           XMonad.ManageHook                (appName, className,
                                                   composeAll, doShift, (-->),
                                                   (<+>), (=?))
import           XMonad.Util.Run                  (spawnPipe) 
import           XMonad.Util.SpawnOnce            (spawnOnce) 

-- docks: add dock (panel) functionality to your configuration
-- ewmh: https://en.wikipedia.org/wiki/Extended_Window_Manager_Hints - lets XMonad talk to panels
main :: IO ()
main = do
  xmobarProc <- spawnPipe "xmobar"
  xmonad . docks . ewmh $ def
    {
      borderWidth = 3
    , handleEventHook = handleEventHook def <+> fullscreenEventHook
    , keys = myKeys
    , layoutHook = myLayoutHook
    , manageHook = myManageHook <+> manageDocks <+> manageHook def
    , terminal = "urxvt"
    , workspaces = myWorkspaces
    , modMask = mod4Mask
    , logHook = dynamicLogWithPP $ xmobarPP
      { ppOutput = hPutStrLn xmobarProc
      , ppCurrent = xmobarColor "#859900" "" . wrap "[" "]"
      , ppVisible = xmobarColor "#2aa198" "" . wrap "(" ")"
      , ppLayout = xmobarColor "#2aa198" ""
      , ppTitle = xmobarColor "#859900" "" . shorten 50
      }
    }

-- Find keys using `xev -event keyboard` and look for the `keysym`.
-- If `xev` doesn't give you the event, try `xmodmap -pk | grep <foo>`
myKeys :: XConfig Layout -> M.Map (XT.ButtonMask, XT.KeySym) (X ())
myKeys conf@XConfig {modMask = modm} =
  let xK_X86MonBrightnessDown = 0x1008ff03
      xK_X86MonBrightnessUp   = 0x1008ff02
      xK_X86AudioLowerVolume  = 0x1008ff11
      xK_X86AudioRaiseVolume  = 0x1008ff13
      xK_X86AudioMute         = 0x1008ff12
      xK_X86AudioPlay         = 0x1008ff14
      xK_X86AudioPrev         = 0x1008ff16
      xK_X86AudioNext         = 0x1008ff17
      spotify c               = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player." <> c
      kees =
        M.fromList [ ((0, XT.xK_Print), spawn "maim -c 1,0,0,0.6 -s ~/screenshots/$(date +%F_%T).png")
                   , ((modm, XT.xK_Print), spawn "maim -s --format png -c 1,0,0,0.6 /dev/stdout | xclip -selection clipboard -t image/png -i")
                   , ((XT.controlMask .|. XT.mod1Mask, XT.xK_l), spawn "xscreensaver-command -lock")
                   , ((0, xK_X86MonBrightnessDown), spawn "brightnessctl s 5%-")
                   , ((0, xK_X86MonBrightnessUp), spawn "brightnessctl s +5%")
                   , ((0, xK_X86AudioLowerVolume), spawn "amixer sset Master 5%-")
                   , ((0, xK_X86AudioRaiseVolume), spawn "amixer sset Master 5%+")
                   , ((0, xK_X86AudioMute), spawn "amixer sset Master toggle")
                   , ((0, xK_X86AudioPlay), spawn (spotify "PlayPause"))
                   , ((0, xK_X86AudioPrev), spawn (spotify "Previous"))
                   , ((0, xK_X86AudioNext), spawn (spotify "Next"))
                   , ((XT.controlMask .|. modm, XT.xK_q), spawn "~/bin/screenlayout laptop")
                   , ((XT.controlMask .|. modm, XT.xK_w), spawn "~/bin/screenlayout work")
                   , ((XT.controlMask .|. modm, XT.xK_e), spawn "~/bin/screenlayout home")
                   , ((modm .|. XT.shiftMask, XT.xK_p), spawn "passmenu")
                   ]
  in kees <> keys def conf

myWorkspaces :: [String]
myWorkspaces =
  [ "1:Web"
  , "2:Work"
  , "3:WorkBrowser"
  , "4:Music"
  , "5"
  , "6"
  , "7:Pass"
  , "8:Mail"
  , "9:Chat"
  ]

-- Class name can be found with `xprop | grep WM_CLASS`
myManageHook :: ManageHook
myManageHook =
  composeAll [ className =? "Emacs" --> doShift "2:Work"
             , className =? "Thunderbird" --> doShift "8:Mail"
             -- Below is the class name for Signal (launched via Chrome)
             , appName =? "Signal" --> doShift "9:Chat"
             , className =? "Spotify" --> doShift "4:Music"
             , isFullscreen --> doFullFloat
             ]

-- avoidStruts tells windows to avoid the "strut" where docks live
myLayoutHook = smartBorders $ avoidStruts $ layoutHook def ||| ThreeColMid 1 (3/100) (1/2)
