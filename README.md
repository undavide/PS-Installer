PS-Installer
============

Multi-version, semi-automatic installation script for Adobe Photoshop ® Add-ons (because I'm *fed up* with Adobe Extension Manager aka AEM and the CC app).

If you develop Photoshop add-ons and want them to be deployed to your users' machines avoiding AEM and/or Creative Clod app installation, this little project of mine might be of some use for you too.

## Features

PS-Installer is able to deploy to their default folders:

- Scripts (JSX)
- HTML Panels
- FLASH Panels
- PS Mac Plug-ins
- PS Win Plug-ins
- Extra items (you provide the destination)

You can choose between a per User installation and a System wide installation.

---

#In a nutshell

1. Distribute your product as a ZIP, let your users unZip it.
2. Instruct the users to open Photoshop, ```File > Scripts > Browse...``` and point to the installer.jsx
3. The script, depending on the PS version, will grab the assets for each product (say, an HTML Panel and a Plug-in) and deploy them into the correct folders.
4. A complete LOG file is created, for debugging purposes

---

#Options
Under construction
### Info
Under construction
### Products
Under construction
### Debug
Under construction

---

## Supported Versions

Currently PS-Installer has been tested from Photoshop CS6 onwards (up to CC 2014), but theoretically it is backward compatible down to CS3.

## License
Copyright (c) 2015 Davide Barranca, [MIT license](LICENSE).