###
 * ===============================================
 * =      Adobe Photoshop Add-ons Installer      =
 * =   (Because Adobe Extension Manager Sucks)   =
 * ===============================================
 *
 *      Copyright: (c)2015-2019, Davide Barranca
 * www.davidebarranca.com || www.cs-extensions.com
 * MIT License: http://opensource.org/licenses/MIT
 *
 *   Thanks to xbytor for his xtools installer,
 *    which has been a source of inspiration!
 *
 * ===============================================
###

###
 * Global object from the JSON
###

initFile = new File "#{File($.fileName).path}/init.json"
unless initFile.exists
	alert "Broken installer!\nThe init.json file is missing...\nPlease get in touch with the original developer."
	throw new Error()

initFile.open "r"
initFileString = initFile.read()
initFile.close()
eval "var G = #{initFileString}"

###
 * Utility functions
 * Mostly borrowed from xbytor's xtools installer
 * http://sourceforge.net/projects/ps-scripts/files/xtools/
 * License: http://www.opensource.org/licenses/bsd-license.php
###
PSU = ((GLOBAL) ->
	that = this
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

		### Recursion if the arg is a File ###
		return createFolder fptr.parent if fptr instanceof File

		### Are we done? ###
		return true if fptr.exists

		unless fptr instanceof Folder
			log fptr.constructor
			Error.runtimeError 21, "Folder is not a Folder?"

		if fptr.parent? and not fptr.parent.exists
			return false unless createFolder fptr.parent

		### eventually...! ###
		rc = fptr.create()
		unless rc then Error.runtimeError 9002, "Unable to create folder #{fptr} (#{fptr.error})\nPlease create it manually and run this script again."
		return rc

	###
	 * Sets up the logging
	 * @param  {string}  logFile      Log file name
	 * @param  {Boolean} isLogEnabled To log or not to log...
	 * @return {void}
	###
	init = (logFile, isLogEnabled) ->
		return unless isLogEnabled
		### LOG Stuff ###
		that.enableLog = isLogEnabled
		that.logFile   = logFile
		### Create Log File Pointer ###
		file = new File that.logFile
		if file.exists then file.remove()
		unless file.open 'w' then throwFileError file, "Unable to open Log file"
		file.lineFeed = 'unix' if isMac()
		that.logFilePointer = file
		return

	return {
		"isMac"            : isMac
		"exceptionMessage" : exceptionMessage
		"log"              : log
		"createFolder"     : createFolder
		"init"             : init
	}

	)(this)

class PSInstaller

	###
	 * Set globals and start the logging
	 * @return {void}
	###
	constructor: () ->


		### set the log file name ###
		G.LOG_FILE = "#{G.LOG_FILE_PATH}/#{G.PRODUCT_NAME}.log"
		### init the logging ###
		PSU.init G.LOG_FILE, G.ENABLE_LOG
		### SCRIPT, FLASH_PANEL, etc. ###
		@productsToInstall = []
		### All the folders to be copied (relative to the ASSETS path) ###
		@foldersList = []
		### List of Deployed Files and Folder - to be used by the uninstaller ###
		@installedFiles = []
		@installedFolders = []

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
				---------------------------------------\n
				\tInstaller Version: #{G.INSTALLER_VERSION}\n
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


	###
	 * Depending on the PS version, sets the available products options
	 * to install (@productsToInstall) and log them
	 * @return {void}
	###
	init: () ->

		that = @

		### Depending on the PS version, what to install
		(not the classiest way I know but it works) ###
		dependencyObj = {
			"10" : [ 				"SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]  # CS3
			"11" : [ "FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CS4
			"12" : [ "FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CS5
			"13" : [ "FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CS6
			"14" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC
			"15" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2014
			"16" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2015
			"17" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2015.5
			"18" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2017
			"19" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2018
			"20" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# CC 2019
			"21" : [ "HTML_PANEL",  "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]	# 2020
		}

		### Array ###
		@productsToInstall = dependencyObj[G.CURRENT_PS_VERSION]

		PSU.log "\nItems to be installed
				\n----------------------------"

		for product in @productsToInstall
			PSU.log "- #{product}"

		return # init

	###
	 * TODO!!
	 * @param  {[Object]} oldVersionsObj An Object containing info about stuff to clean before installing new ones
	 * @return {[void]}
	###
	clean: (oldVersionsObj) ->

		###
		 * Delete a Folder (recursively, with ALL its content)
		 * or a single file
		 * @param  {File or Folder object} thingToDestroy The object to remove
		###
		recursivelyDeleteThing = (thingToDestroy) ->

			inFolders = []
			inFiles   = []

			processFolder = (fold) ->
				fileList = fold.getFiles()
				for aThing in fileList
					if aThing instanceof Folder
						inFolders.push aThing
						processFolder aThing
					else
						inFiles.push aThing

			if thingToDestroy instanceof File
				try
					thingToDestroy.remove()
				catch e

				return

			if thingToDestroy instanceof Folder

				processFolder thingToDestroy
				inFolders.unshift thingToDestroy
				inFolders.reverse()
				# $.writeln aFile for aFile in inFiles
				# $.writeln aFolder for aFolder in inFolders
				for aFile in inFiles
					try
						aFile.remove()
					catch e

				for aFolder in inFolders
					try
						aFolder.remove()
					catch e

				return
			return
		###
		 * Delete recursively a File or Folder which CONTAINS a string,
		 * e.g. recursivelyDeleteThing("this", "~/Desktop/TEST") will catch
		 * "com.this.example" and so on and so forth
		 * @param  {String} thingToDestroy What the File or Folder name should contain
		 * @param  {String} startFolder    The start folder
		###
		recursivelyDeleteThingFromFolder = (thingToDestroy, startFolder) ->

			inFolders = []
			inFiles   = []

			escapeRegExp = (stringToGoIntoTheRegex) ->
				stringToGoIntoTheRegex = stringToGoIntoTheRegex.name if stringToGoIntoTheRegex instanceof Folder
				stringToGoIntoTheRegex.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

			processFolder = (fold) ->
				fileList = fold.getFiles()
				for aThing in fileList
					if aThing instanceof Folder
						inFolders.push aThing
						processFolder aThing
					else
						inFiles.push aThing

			processFolder Folder startFolder

			matchString = escapeRegExp thingToDestroy
			re = new RegExp matchString, "gi"

			for aFile in inFiles
				aFile.remove() if aFile.name.match re

			for aFolder in inFolders
				recursivelyDeleteThing aFolder if aFolder.name.match re

			return

		return

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
			that.installedFolders.push "#{destinationToWriteFolder.fsName}"
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
					### For the uninstaller ###
					that.installedFiles.push "#{folder}/#{File(eachFile).name}"
					PSU.log "Copied:\t\t#{File(eachFile).name}"

		### Routine ###
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
					panelsPath = "#{if G.SYSTEM_INSTALL then Folder.commonFiles else Folder.userData}/Adobe/#{if G.CURRENT_PS_VERSION is '14' then 'CEPServiceManager4' else 'CEP'}/extensions"
					destinationPath = "#{panelsPath}/#{G.PRODUCT_ID}"

				when "MAC_PLUGIN"
					if $.os.match /windows/i
						destinationPath = ""
						break
					if G.SHARED_PLUGINS and G.CURRENT_PS_VERSION > 13
						pluginsPath = "#{Folder.commonFiles}/Adobe/#{localize '$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'}/CC"
					else
						pluginsPath = "#{app.path}/#{localize '$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'}"
					destinationPath = "#{pluginsPath}/#{G.COMPANY}"

				when "WIN_PLUGIN"
					unless $.os.match /windows/i
						destinationPath = ""
						break
					if G.SHARED_PLUGINS and G.CURRENT_PS_VERSION > 13
						pluginsPath = "#{Folder.commonFiles}/Adobe/#{localize '$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'}/CC"
					else
						pluginsPath = "#{app.path}/#{localize '$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'}"
					destinationPath = "#{pluginsPath}/#{G.COMPANY}"

				when "EXTRA"
					### TODO ###
					destinationPath = G.EXTRA

			if destinationPath is "" then continue
			PSU.log "\n\nAdding #{product}\n----------------------------\nDestination folder: #{Folder(destinationPath).fsName}"
			### Create destination Folder ###
			if PSU.createFolder destinationPath then PSU.log "Destination Folder successfully created.\n" else PSU.log "ERROR! Can't create destination folder."

			### Create the Folder for the source from the string path ###
			sourceFolder = Folder "#{G.CURRENT_PATH}/#{G[product]}"
			### Create the Folder for the destination from the string path ###
			destinationFolder = Folder destinationPath
			### Reset the array containing all the folders to be created in the destination ###
			@foldersList = []
			### Fill the foldersList ###
			PSU.log "List of Folders to be copied for the #{product}:"
			### Log is in the getFolderl ###
			getFoldersList sourceFolder
			### Add the root folder to the list ###
			@foldersList.unshift sourceFolder
			PSU.log "Folder: #{sourceFolder}"

			### Create Folders tree in destination ###
			PSU.log "\nCreating Folders in destination and copying files:\n"
			### RegExp for ignoring files to be copied ###
			ignoreRegExp = if G.IGNORE then new RegExp((G.IGNORE.join "|"), "i") else new RegExp "$."

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
		alert "Complete!" + (G.ENABLE_LOG ? "\nAn installation LOG file has been created in:\n#{G.LOG_FILE}" : "")
		alert "Restart Photoshop\nYou must restart the application in orded to use #{G.PRODUCT_NAME}, thank you!"
		if G.README then (File "#{G.CURRENT_PATH}/#{G.README}").execute()

	createUninstaller: () ->

		uninstall = (files, folders) ->
			return unless performInstallation = confirm "#{G.PRODUCT_NAME} Version #{G.PRODUCT_VERSION} Uninstaller\nAre you sure to remove #{G.PRODUCT_NAME}?"
			uninstallErrors = false
			G.LOG_FILE = "#{G.LOG_FILE_PATH}/#{G.PRODUCT_NAME} Uninstaller.log"
			### init the logging ###
			PSU.init G.LOG_FILE, true
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
				---------------------------------------\n
				\tInstaller Version: #{G.INSTALLER_VERSION}\n
				=======================================
				"

			PSU.log "\nRemoving FILES..."

			for eachFile in files
				try
					file = File eachFile
					PSU.log "Removing:\t#{file.fsName}..."
					file.remove()
					PSU.log "Done!"
				catch e
					PSU.log "ERROR!"
					uninstallErrors = true
			PSU.log "---------------------------------------\n
					Removing FOLDERS..."

			for eachFolder in folders by -1
				try
					folder = Folder eachFolder
					PSU.log "Removing:\t#{folder.fsName}..."
					folder.remove()
					PSU.log "Done!"
				catch e
					PSU.log "ERROR!"
					uninstallErrors = true

				if uninstallErrors
					alert "Something went wrong!\nA uninstallation LOG file has been created in:\n#{G.LOG_FILE}, please send it to #{G.CONTACT_INFO}"
					throw Error "Restart Photoshop and see if the product has been uninstalled anyway."

			alert "#{G.PRODUCT_NAME} successfully Removed\nPlease Restart Photoshop for the changes to take effect."

		uninstaller = new File "#{G.CURRENT_PATH}/#{G.PRODUCT_NAME}_V#{G.PRODUCT_VERSION} - UNINSTALLER.jsx"
		unless uninstaller.open 'w' then throwFileError uninstaller, "Unable to Write the Uninstaller file"
		uninstaller.lineFeed = 'unix' if PSU.isMac()
		uninstaller.writeln "var G = #{G.toSource()}"
		### This won't work :-/
		uninstaller.writeln "var PSU = #{PSU.toSource()}" ###
		uninstaller.writeln "var PSU=(function(GLOBAL){var createFolder,exceptionMessage,init,isMac,isWindows,log,that,throwFileError;that=this;this.enableLog=void 0;this.logFile=void 0;this.logFilePointer=void 0;isWindows=function(){return $.os.match(/windows/i);};isMac=function(){return!isWindows();};throwFileError=function(f,msg){if(msg==null){msg='';}return Error.runtimeError(9002,''+msg+''+f+': '+f.error+'.');};exceptionMessage=function(e){var fname,str;fname=!e.fileName?'???':decodeURI(e.fileName);str='  Message: '+e.message+'	File: '+fname+'\\tLine: '+(e.line||'???')+'\\n\\tError Name: '+e.name+'\\n\\tError Number: '+e.number;if($.stack){str+='  '+$.stack;}return str;};log=function(msg){var file;if(!that.enableLog){return;}file=that.logFilePointer;if(!file.open('e')){throwFileError(file,'Unable to open Log file');}file.seek(0,2);if(!file.writeln(''+msg)){return throwFileError(file,'Unable to write to log file');}};createFolder=function(fptr){var rc;if(fptr==null){Error.runtimeError(19,'No Folder name specified');}if(fptr.constructor===String){fptr=new Folder(fptr);}if(fptr instanceof File){return createFolder(fptr.parent);}if(fptr.exists){return true;}if(!(fptr instanceof Folder)){log(fptr.constructor);Error.runtimeError(21,'Folder is not a Folder?');}if((fptr.parent!=null)&&!fptr.parent.exists){if(!createFolder(fptr.parent)){return false;}}rc=fptr.create();if(!rc){Error.runtimeError(9002,'Unable to create folder '+fptr+' ('+fptr.error+') Please create it manually and run this script again.');}return rc;};init=function(logFile,isLogEnabled){var file;if(!isLogEnabled){return;}that.enableLog=isLogEnabled;that.logFile=logFile;file=new File(that.logFile);if(file.exists){file.remove();}if(!file.open('w')){throwFileError(file,'Unable to open Log file');}if(isMac()){file.lineFeed='unix';}that.logFilePointer=file;};return{'isMac':isMac,'exceptionMessage':exceptionMessage,'log':log,'createFolder':createFolder,'init':init};})(this);"
		uninstaller.writeln "var filesToRemove = #{@installedFiles.toSource()};"
		uninstaller.writeln "var foldersToRemove = #{@installedFolders.toSource()};"
		uninstaller.writeln "var uninstall = #{uninstall.toSource()};"
		uninstaller.writeln "uninstall(filesToRemove, foldersToRemove);"
		uninstaller.close()

try
	psInstaller = new PSInstaller()
	psInstaller.preflight()
	psInstaller.init()
	psInstaller.clean()
	psInstaller.copy()
	psInstaller.createUninstaller()
	psInstaller.wrapUp()
catch e
	errorMessage = "Installation failed: #{PSU.exceptionMessage e}"
	PSU.log errorMessage
	alert "Something went wrong!\n#{errorMessage}\nPlease contact #{G.CONTACT_INFO}, thank you."

### EOF ###
"psInstaller"
