###
 * ===============================================
 * =      Adobe Photoshop Add-ons Installer      =
 * =   (Because Adobe Extension Manager Sucks)   =
 * ===============================================
 * 
 *      Copyright: (c)2015, Davide Barranca
 * www.davidebarranca.com || www.cs-extensions.com
 * MIT License: http://opensource.org/licenses/MIT
 * 
 *   Thanks to xbytor for his xtools installer,
 *    which has been a source of inspiration!
 * 
 * ===============================================
###

G = {

	# INFO ======================================= 
	
	COMPANY         : "CS-EXTENSIONS"
	CONTACT_INFO    : "support@cs-extensions.com"
	PRODUCT_NAME    : "Test product"
	PRODUCT_ID      : "com.cs-extensions.test"
	PRODUCT_VERSION : "0.1.0"

	# PRODUCTS ===================================

	# Photoshop versions range
	# Leave undefined for no limit
	MIN_VERSION	 : undefined
	MAX_VERSION  : undefined

	# Product Source Folders
	# Leave undefined for no product to install
	# Make sure tha paths (relative to the installer.jsx) do NOT start or end with "/"
	HTML_PANEL   : "ASSETS/HTML"
	FLASH_PANEL  : "ASSETS/FLASH"
	SCRIPT       : "ASSETS/SCRIPT"
	MAC_PLUGIN   : "ASSETS/MAC_PLUGIN"
	WIN_PLUGIN   : "ASSETS/WIN_PLUGIN"
	EXTRA        : undefined 
	
	# If you have a readme file to display, put it here (path and filename)
	README       : "ASSETS/readme.txt"
	# System vs. User installation
	SYSTEM_INSTALL : false

	# DEBUG =====================================

	ENABLE_LOG	 : true
	LOG_FILE_PATH: "~/Desktop" # no trailing /
	# will be created as LOG_FILE_PATH / PRODUCT_NAME.log
	LOG_FILE     : ""
	# Files to be ignored (escape "\" -> "\\")
	IGNORE		 : [ 
		"^\\.\\w+",	# starting with .
		"^\\_\\w+", # starting with _
	]
	
	# UTILS =====================================

	CURRENT_PATH : File($.fileName).path
	CURRENT_PS_VERSION : app.version.split('.')[0]

}

###
 * Utility functions
 * Mostly borrowed from xbytor's xtools installer 
 * http://sourceforge.net/projects/ps-scripts/files/xtools/
 * License: http://www.opensource.org/licenses/bsd-license.php
###
PSU = ((GLOBAL) ->

	that = @
	@enableLog      = undefined
	@logFile        = undefined
	@logFilePointer = undefined

	isWindows = () -> $.os.match /windows/i
	isMac     = () -> !isWindows()

	throwFileError = (f, msg) ->
		unless msg? then msg = ''
		Error.runtimeError 9002, "#{msg}\"#{f}\": #{f.error}."

	exceptionMessage = (e) ->
		fname = if !e.fileName then '???' else decodeURI e.fileName
		str = "\tMessage: #{e.message}\n\tFile: #{fname}\n\tLine: #{e.line or '???'}\n\tError Name: #{e.name}\n\tError Number: #{e.number}"
		if $.stack then str += "\t#{$.stack}"
		str

	log = (msg) ->
		return unless that.enableLog
		file = that.logFilePointer
		unless file.open 'e' then throwFileError file, "Unable to open Log file"
		file.seek 0, 2 # jump to the end of the file (0 from the end)
		unless file.writeln "#{msg}" then throwFileError file, "Unable to write to log file"

	createFolder = (fptr) ->
		unless fptr? then Error.runtimeError 19, "No Folder name specified" 
		fptr = new Folder fptr if fptr.constructor is String
		
		# Recursion if the arg is a File
		return createFolder fptr.parent if fptr instanceof File

		# Are we done?
		return true if fptr.exists

		unless fptr instanceof Folder
			log fptr.constructor
			Error.runtimeError 21, "Folder is not a Folder?"

		if fptr.parent? and not fptr.parent.exists
			return false unless createFolder fptr.parent

		# eventually...!
		rc = fptr.create()
		unless rc then Error.runtimeError 9002, "Unable to create folder '#{fptr}' (#{fptr.error})\nPlease create it manually and run this script again."
		return rc

	###
	 * Sets up the logging
	 * @param  {string}  logFile      Log file name
	 * @param  {Boolean} isLogEnabled To log or not to log...
	 * @return {void}               
	###
	init = (logFile, isLogEnabled) ->
		
		# LOG Stuff
		that.enableLog = isLogEnabled
		that.logFile   = logFile
		# Create Log File Pointer
		file = new File that.logFile
		if file.exists then file.remove()
		unless file.open 'w' then throwFileError file, "Unable to open Log file"
		file.lineFeed = 'unix' if isMac()
		that.logFilePointer = file
		return

	return {
		"exceptionMessage" : exceptionMessage
		"log"              : log
		"createFolder"     : createFolder
		"init"             : init
	}

	)()

class PSInstaller

	###
	 * Set globals and start the logging
	 * @return {void} 
	###
	constructor: () ->
		# set the log file name
		G.LOG_FILE = "#{G.LOG_FILE_PATH}/#{G.PRODUCT_NAME}.log"
		# init the logging
		PSU.init G.LOG_FILE, G.ENABLE_LOG
		# SCRIPT, FLASH_PANEL, etc.
		@productsToInstall = []
		# All the folders to be copied
		@foldersList = []

		PSU.log "
				=======================================\n
				#{new Date()}\n
				\tCompany: #{G.COMPANY}\n
				\tProduct: #{G.PRODUCT_NAME}\n
				\tProduct version: #{G.PRODUCT_VERSION}\n
				\tApp: #{BridgeTalk.appName}\n
				\tApp Version: #{app.version}\n
				\tOS: #{$.os}\n
				\tLocale: #{$.locale}\n
				=======================================
				"

		return # constructor

	###
	 * App compatibility check
	 * @return {} 
	###
	preflight: () ->
		G.MIN_VERSION = G.MIN_VERSION || 0
		G.MAX_VERSION = G.MAX_VERSION || 99

		PSU.log "\nPreflight
				\n----------------------------"

		if G.MIN_VERSION <= G.CURRENT_PS_VERSION <= G.MAX_VERSION 

			PSU.log "OK: PS version #{G.CURRENT_PS_VERSION} in the range [#{G.MIN_VERSION}, #{G.MAX_VERSION}]"
			alert "#{G.COMPANY} - #{G.PRODUCT_NAME}\nPress OK to start the installation.\nThe process is going to be completed in a short while."
			return true 

		else 
			PSU.log "\nFAIL: PS version #{G.CURRENT_PS_VERSION} not in the range [#{G.MIN_VERSION}, #{G.MAX_VERSION}]"
			Error.runtimeError 9002, "Bad Photoshop version.\n#{G.CURRENT_PS_VERSION} not in the range [#{G.MIN_VERSION}, #{G.MAX_VERSION}]"


	init: () ->

		that = @

		# Depending on the PS version, what to install
		# (not the classiest way I know but it works)
		dependencyObj = {
			"10" : [ 				"SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]  # CS3
			"11" : [ "FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CS4
			"12" : [ "FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CS5
			"13" : [ "FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CS6
			"14" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC
			"15" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2014
			"16" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2015
		}

		# Array
		@productsToInstall = dependencyObj[G.CURRENT_PS_VERSION]

		PSU.log "\nItems to be installed
				\n----------------------------"

		for product in @productsToInstall
			PSU.log "- #{product}"

		return # init

	copy: () ->

		that = @

		###
		 * [createRelativeFolder description]
		 * @param  {folder} destination 	the destination Folder
		 * @param  {folder} origin      	the original, existing Folder
		 * @param  {folder} base 			the Folder used as a base
		 * @return {folder}	a new created folder in the destination
		###
		createRelativeFolder = (destination, origin, base) ->

			destinationArray = decodeURI(destination).toString().split('/')
			originArray = decodeURI(origin).toString().split('/')
			originBaseArray = decodeURI(base).toString().split('/')
			# normalize the url removing the origin folder hierarchy
			originArray.splice 0, originBaseArray.length

			destinationToWriteArray = destinationArray.concat originArray
			destinationToWriteString = destinationToWriteArray.join '/'
			destinationToWriteFolder = Folder destinationToWriteString
			unless destinationToWriteFolder.exists then destinationToWriteFolder.create()
			PSU.log "Created Folder:\t#{destinationToWriteFolder.fsName}"
			destinationToWriteFolder

		###
		 * process the folder and fills the external
		 * array of folders foldersList
		 * @param  {folder} folder 
		 * @return {void} 	
		###
		getFoldersList = (folder) ->	
			if folder.constructor is String then folder = new Folder folder
			list = folder.getFiles()
			i = 0
			for item in list
				if item instanceof Folder
					that.foldersList.push item
					PSU.log "Folder: #{item.fsName}"
					getFoldersList item
			return

		###
		 * Copy Files to a Folder
		 * @param  {array} files  Array of strings (File paths)
		 * @param  {string} folder Folder path to copy to
		 * @return {void}        
		###
		copyFiles = (files, folder) ->
			filesList = []
			filesList.push decodeURI file for file in files
			for eachFile in filesList
				if File(eachFile).exists 
					File(eachFile).copy "#{folder}/#{File(eachFile).name}"
					PSU.log "Copied:\t\t#{File(eachFile).name}"

		for product in @productsToInstall

			unless G[product]
				PSU.log "\n#{product} - Nothing to install\n"
				continue
			
			switch product

				when "SCRIPT"
					scriptsPath = "#{app.path}/#{localize '$$$/ScriptingSupport/InstalledScripts=Presets/Scripts'}"
					destinationPath = "#{scriptsPath}/#{G.COMPANY}/#{G.PRODUCT_NAME}" 
					
				when "FLASH_PANEL"
					panelsPath = "#{if G.SYSTEM_INSTALL then Folder.commonFiles else Folder.userData}/Adobe/CS#{G.CURRENT_PS_VERSION - 7}ServiceManager/extensions"
					destinationPath = "#{panelsPath}/#{G.PRODUCT_ID}" 

				when "HTML_PANEL"
					panelsPath = "#{if G.SYSTEM_INSTALL then Folder.commonFiles else Folder.userData}/Adobe/#{if G.CURRENT_PS_VERSION is 14 then 'CEPServiceManager4' else 'CEP'}/extensions"
					destinationPath = "#{panelsPath}/#{G.PRODUCT_ID}" 

				when "MAC_PLUGIN"
					if $.os.match /windows/i 
						destinationPath = ""
						break
					pluginsPath = "#{app.path}/#{localize '$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'}"
					destinationPath = "#{pluginsPath}/#{G.COMPANY}" 

				when "WIN_PLUGIN"
					unless $.os.match /windows/i 
						destinationPath = ""
						break
					pluginsPath = "#{app.path}/#{localize '$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'}"
					destinationPath = "#{pluginsPath}/#{G.COMPANY}"

				when "EXTRA"
					destinationPath = G.EXTRA
					
			if destinationPath is "" then continue
			PSU.log "\n\nAdding #{product}\n----------------------------\nDestination folder: #{Folder(destinationPath).fsName}"
			# Create destination Folder
			if PSU.createFolder destinationPath then PSU.log "Destination Folder successfully created.\n" else PSU.log "ERROR! Can't create destination folder."

			# Create the Folder for the source from the string path
			sourceFolder = Folder "#{G.CURRENT_PATH}/#{G[product]}"
			# Create the Folder for the destination from the string path
			destinationFolder = Folder destinationPath 
			# Reset the array containing all the folders to be created in the destination
			@foldersList = []
			# Fill the foldersList
			PSU.log "List of Folders to be copied for the #{product}:"
			# Log is in the getFolderl
			getFoldersList sourceFolder
			# Add the root folder to the list
			@foldersList.unshift sourceFolder
			PSU.log "Folder: #{sourceFolder}"

			# Create Folders tree in destination
			PSU.log "\nCreating Folders in destination and copying files:\n"
			# RegExp for ignoring files to be copied
			ignoreRegExp = new RegExp (G.IGNORE.join "|"), "i"

			for eachFolder in @foldersList
				saveFolder = createRelativeFolder destinationFolder, eachFolder, sourceFolder
				allFiles = eachFolder.getFiles( (f) -> 
					if (f instanceof Folder) 
						return false 
					else 
						if (f.name.match ignoreRegExp)? then return false
						return true
				)
				if allFiles.length then copyFiles allFiles, saveFolder 

			PSU.log "\nEnded copying files for #{product}."

	wrapUp: () ->
		alert "Complete!\nAn installation LOG file has been created in:\n#{G.LOG_FILE}"
		alert "Restart Photoshop\nYou must restart the application in orded to use #{G.PRODUCT_NAME}, thank you!"
		if G.README then (File "#{G.CURRENT_PATH}/#{G.README}").execute()

try
	psInstaller = new PSInstaller()
	psInstaller.preflight()
	psInstaller.init()
	psInstaller.copy()
	psInstaller.wrapUp()	
catch e
	errorMessage = "Installation failed: #{PSU.exceptionMessage e}"
	PSU.log errorMessage
	alert "Something went wrong!\n#{errorMessage}\nPlease contact #{G.CONTACT_INFO}"

# EOF
"psInstaller"
