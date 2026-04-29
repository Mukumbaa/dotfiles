#!/usr/bin/env lua

-- Arresta i servizi utente di xdg-desktop-portal
os.execute("systemctl --user stop xdg-document-portal.service xdg-desktop-portal.service")

-- Spegne il sistema
os.execute("shutdown -h now")
