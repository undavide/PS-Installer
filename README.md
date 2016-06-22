PS-Installer
============

Multi-version, semi-automatic installation script for Adobe Photoshop ® Add-ons (Adobe Extension Manager **has been discontinued** so it will be of no use for CC2015.x products. Please have a look at this [CC 2015 Survival Guide](http://www.davidebarranca.com/2015/06/html-panel-tips-17-cc2015-survival-guide/) and [CC 2015.5 Survival Guide](http://www.davidebarranca.com/2016/06/html-panel-tips-21-photoshop-cc2015-5-2016-survival-guide/)for more info). Compatibility is in the range CS3..CC2015.5.

If you develop Photoshop add-ons and want them to be deployed to your users' machines avoiding AEM and/or Creative Cloud app installation, this little project of mine might be of some use for you too.

## Features

PS-Installer is able to deploy to their PS or System default folders:

- Scripts
- HTML Panels
- FLASH Panels
- PS Mac Plug-ins
- PS Win Plug-ins
- Extra items (you provide the destination)

You can choose between per User installation and System wide installation.

# In a nutshell

1. Distribute your product as a ZIP, let your users unZip it.
2. Instruct the users to open Photoshop, ```File > Scripts > Browse...``` and point to the ```installer.jsx```
3. The script will grab the assets for each product (say, an HTML Panel and a Script, or a Plugin) and deploy them into the correct folders depending on the PS version (i.e. HTML Panel for CC onwards, Flash one for CS6, etc.) 
4. A complete LOG file is created, for debugging purposes

An example folder tree is as follows - find it in the project's example folder:

	.
	├── ASSETS
	│   ├── FLASH
	│   │   ├── CSXS
	│   │   │   └── manifest.xml
	│   │   └── example.swf
	│   ├── HTML
	│   │   ├── CSXS
	│   │   │   └── manifest.xml
	│   │   └── example.html
	│   ├── MAC_PLUGIN
	│   │   └── example.plugin
	│   ├── SCRIPT
	│   │   ├── Folder\ A
	│   │   │   ├── Subfolder\ A
	│   │   │   │   └── fileD.jsx
	│   │   │   └── fileC.jsx
	│   │   ├── Folder\ B
	│   │   │   └── fileE.jsx
	│   │   ├── fileA.jsx
	│   │   └── fileB.jsx
	│   ├── WIN_PLUGIN
	│   │   └── example.8bf
	│   └── readme.txt
	└── installer.jsx


# Uninstallation
The installer, while deploying your assets, will write a uninstaller script in its same folder - this can be used later on to remove the product.

# Options
You can configure the installer using properties of the object contained in the  ```init.json``` sidecar file (which must be included alongside the ```installer.jsx```). Here they are documented.

### COMPANY
[String] - Your company's name 
### CONTACT_INFO
[String] - The email for customer support inquiries.
### PRODUCT_NAME
[String] - The descriptive name of the product to install.
### PRODUCT_ID
[String] - Needed for Panels: ID as a reverse URL (e.g. com.cs-extensions.VitaminBW)
### PRODUCT_VERSION
[String] - Yours (not PS), to be written in the LOG file
### MIN_VERSION
[Number] - Minimum Photoshop version required (e.g. 13.0), leave ```undefined``` for no limit.
### MAX_VERSION
[Number] - Maximum Photoshop version supported (e.g. 15.2), leave ```undefined``` for no limit.
### HTML_PANEL
[String] - Relative Path for HTML Panel (no ```/``` at the start or end, e.g. "ASSETS/HTML")
### FLASH_PANEL
[String] - Relative Path for Flash Panel (no ```/``` at the start or end, e.g. "ASSETS/FLASH")
### SCRIPT
[String] - Relative Path for Script (no ```/``` at the start or end, e.g. "ASSETS/SCRIPT")
### MAC_PLUGIN
[String] - Relative Path for Mac Plugin (no ```/``` at the start or end, e.g. "ASSETS/MAC")
### WIN_PLUGIN
[String] - Relative Path for Win Plugin (no ```/``` at the start or end, e.g. "ASSETS/WIN")
### EXTRA
[String] - Relative Path for Extra content (no ```/``` at the start or end, e.g. "ASSETS/EXTRA") - **not supported yet**
### README
[String] - Relative Path for the optional Readme file (e.g. "ASSETS/Readme.txt")
### SYSTEM_INSTALL
[Boolean] - false: install the Panel (if present) for all users - false: install it only for the current user. There's an open issue under Windows with Photoshop @64bit and Global installation - please set ```SYSTEM_INSTALL = false```.
### SHARED_PLUGINS
[Boolean] - false: install the Filters (if present) in a shared location (for CC onwards) - false: install them on ```Photoshop <version>/Plug-ins/```. true: installs them on ```/Library/Application Support/Adobe/Plug-Ins/CC/``` on Mac and ```\Program Files\Common Files\Adobe\Plug-Ins\CC``` on Windows.
### ENABLE_LOG
[Boolean] - Enable installation logging (highly recommended)
### LOG_FILE_PATH
[String] - Absolute Path for the LOG file, (no ```/``` at the start or end, e.g. "~/Desktop")
### LOG_FILE
Leave it as an empty string - will be created at runtime as ```LOG_FILE_PATH/PRODUCT_NAME.log```
### IGNORE
[Array of String] RegExp for Files to ignore during installation, e.g. ```["^\\.\\w+"]``` - remember to escape ```\```

This first looked to me like a clever idea, yet I've seen it might break Signing/Timestamping. As a temporary workaround in case of such kind of errors during installation, use ```IGNORE: ["$."]``` (which basically ignores nothing - don't let it empty, the regex will match everything).

---

## Supported Versions

Currently PS-Installer has been tested from Photoshop CS6 onwards (up to CC 2015), but theoretically it is backward compatible down to CS3.

## License
Copyright (c) 2015 Davide Barranca, [MIT license](LICENSE).