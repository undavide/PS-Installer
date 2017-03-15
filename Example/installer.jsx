/*
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
 */

/*
 * Global object from the JSON
 */
var PSInstaller, PSU, e, errorMessage, initFile, initFileString, psInstaller;

initFile = new File((File($.fileName).path) + "/init.json");

if (!initFile.exists) {
  alert("Broken installer!\nThe init.json file is missing...\nPlease get in touch with the original developer.");
  throw new Error();
}

initFile.open("r");

initFileString = initFile.read();

initFile.close();

eval("var G = " + initFileString);


/*
 * Utility functions
 * Mostly borrowed from xbytor's xtools installer 
 * http://sourceforge.net/projects/ps-scripts/files/xtools/
 * License: http://www.opensource.org/licenses/bsd-license.php
 */

PSU = (function(GLOBAL) {
  var createFolder, exceptionMessage, init, isMac, isWindows, log, that, throwFileError;
  that = this;
  this.enableLog = void 0;
  this.logFile = void 0;
  this.logFilePointer = void 0;
  isWindows = function() {
    return $.os.match(/windows/i);
  };
  isMac = function() {
    return !isWindows();
  };
  throwFileError = function(f, msg) {
    if (msg == null) {
      msg = '';
    }
    return Error.runtimeError(9002, msg + "\"" + f + "\": " + f.error + ".");
  };
  exceptionMessage = function(e) {
    var fname, str;
    fname = !e.fileName ? '???' : decodeURI(e.fileName);
    str = "\tMessage: " + e.message + "\n\tFile: " + fname + "\n\tLine: " + (e.line || '???') + "\n\tError Name: " + e.name + "\n\tError Number: " + e.number;
    if ($.stack) {
      str += "\t" + $.stack;
    }
    return str;
  };
  log = function(msg) {
    var file;
    if (!that.enableLog) {
      return;
    }
    file = that.logFilePointer;
    if (!file.open('e')) {
      throwFileError(file, "Unable to open Log file");
    }
    file.seek(0, 2);
    if (!file.writeln("" + msg)) {
      return throwFileError(file, "Unable to write to log file");
    }
  };
  createFolder = function(fptr) {
    var rc;
    if (fptr == null) {
      Error.runtimeError(19, "No Folder name specified");
    }
    if (fptr.constructor === String) {
      fptr = new Folder(fptr);
    }

    /* Recursion if the arg is a File */
    if (fptr instanceof File) {
      return createFolder(fptr.parent);
    }

    /* Are we done? */
    if (fptr.exists) {
      return true;
    }
    if (!(fptr instanceof Folder)) {
      log(fptr.constructor);
      Error.runtimeError(21, "Folder is not a Folder?");
    }
    if ((fptr.parent != null) && !fptr.parent.exists) {
      if (!createFolder(fptr.parent)) {
        return false;
      }
    }

    /* eventually...! */
    rc = fptr.create();
    if (!rc) {
      Error.runtimeError(9002, "Unable to create folder " + fptr + " (" + fptr.error + ")\nPlease Run Photoshop in Admin Mode and run this script again.");
    }
    return rc;
  };

  /*
     * Sets up the logging
     * @param  {string}  logFile      Log file name
     * @param  {Boolean} isLogEnabled To log or not to log...
     * @return {void}
   */
  init = function(logFile, isLogEnabled) {
    var file;
    if (!isLogEnabled) {
      return;
    }

    /* LOG Stuff */
    that.enableLog = isLogEnabled;
    that.logFile = logFile;

    /* Create Log File Pointer */
    file = new File(that.logFile);
    if (file.exists) {
      file.remove();
    }
    if (!file.open('w')) {
      throwFileError(file, "Unable to open Log file");
    }
    if (isMac()) {
      file.lineFeed = 'unix';
    }
    that.logFilePointer = file;
  };
  return {
    "isMac": isMac,
    "exceptionMessage": exceptionMessage,
    "log": log,
    "createFolder": createFolder,
    "init": init
  };
})(this);

PSInstaller = (function() {

  /*
     * Set globals and start the logging
     * @return {void}
   */
  function PSInstaller() {

    /* set the log file name */
    G.LOG_FILE = G.LOG_FILE_PATH + "/" + G.PRODUCT_NAME + ".log";

    /* init the logging */
    PSU.init(G.LOG_FILE, G.ENABLE_LOG);

    /* SCRIPT, FLASH_PANEL, etc. */
    this.productsToInstall = [];

    /* All the folders to be copied (relative to the ASSETS path) */
    this.foldersList = [];

    /* List of Deployed Files and Folder - to be used by the uninstaller */
    this.installedFiles = [];
    this.installedFolders = [];
    PSU.log("=======================================\n " + (new Date()) + "\n \tCompany: " + G.COMPANY + "\n \tProduct: " + G.PRODUCT_NAME + "\n \tProduct version: " + G.PRODUCT_VERSION + "\n \tApp: " + BridgeTalk.appName + "\n \tApp Version: " + app.version + "\n \tOS: " + $.os + "\n \tLocale: " + $.locale + "\n ---------------------------------------\n \tInstaller Version: " + G.INSTALLER_VERSION + "\n =======================================");
    return;
  }


  function endsWith(str, suffix) {
      return str.indexOf(suffix, str.length - suffix.length) !== -1;
  }
  /*
     * App compatibility check
     * @return {}
   */

  PSInstaller.prototype.preflight = function() {
    var ref;
    G.MIN_VERSION = G.MIN_VERSION || 0;
    G.MAX_VERSION = G.MAX_VERSION || 99;
    PSU.log("\nPreflight \n----------------------------");
    if ((G.MIN_VERSION <= (ref = G.CURRENT_PS_VERSION) && ref <= G.MAX_VERSION)) {
      PSU.log("OK: PS version " + G.CURRENT_PS_VERSION + " in the range [" + G.MIN_VERSION + ", " + G.MAX_VERSION + "]");
      alert(G.COMPANY + " - " + G.PRODUCT_NAME + "\nPress OK to start the installation.\nThe process is going to be completed in a short while.");
      return true;
    } else {
      PSU.log("\nFAIL: PS version " + G.CURRENT_PS_VERSION + " not in the range [" + G.MIN_VERSION + ", " + G.MAX_VERSION + "]");
      return Error.runtimeError(9002, "Bad Photoshop version.\n" + G.CURRENT_PS_VERSION + " not in the range [" + G.MIN_VERSION + ", " + G.MAX_VERSION + "]");
    }
  };


  /*
     * Depending on the PS version, sets the available products options 
     * to install (@productsToInstall) and log them
     * @return {void}
   */

  PSInstaller.prototype.init = function() {
    var dependencyObj, j, len, product, ref, that;
    that = this;

    /* Depending on the PS version, what to install
        (not the classiest way I know but it works)
     */
    dependencyObj = {
      "10": ["SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "11": ["FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "12": ["FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "13": ["FLASH_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "14": ["HTML_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "15": ["HTML_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "16": ["HTML_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "17": ["HTML_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"],
      "18": ["HTML_PANEL", "SCRIPT", "MAC_PLUGIN", "WIN_PLUGIN", "EXTRA"]
    };
    /* Array */
    this.productsToInstall = dependencyObj[G.CURRENT_PS_VERSION];
    PSU.log("\nItems to be installed \n----------------------------");
    ref = this.productsToInstall;
    for (j = 0, len = ref.length; j < len; j++) {
      product = ref[j];
      PSU.log("- " + product);
    }
  };


  /*
     * TODO!!
     * @param  {[Object]} oldVersionsObj An Object containing info about stuff to clean before installing new ones
     * @return {[void]}
   */

  PSInstaller.prototype.clean = function(oldVersionsObj) {

    /*
         * Delete a Folder (recursively, with ALL its content)
         * or a single file
         * @param  {File or Folder object} thingToDestroy The object to remove
     */
    var recursivelyDeleteThing, recursivelyDeleteThingFromFolder;
    recursivelyDeleteThing = function(thingToDestroy) {
      var aFile, aFolder, e, inFiles, inFolders, j, k, len, len1, processFolder;
      inFolders = [];
      inFiles = [];
      processFolder = function(fold) {
        var aThing, fileList, j, len, results;
        fileList = fold.getFiles();
        results = [];
        for (j = 0, len = fileList.length; j < len; j++) {
          aThing = fileList[j];
          if (aThing instanceof Folder) {
            inFolders.push(aThing);
            results.push(processFolder(aThing));
          } else {
            results.push(inFiles.push(aThing));
          }
        }
        return results;
      };
      if (thingToDestroy instanceof File) {
        try {
          thingToDestroy.remove();
        } catch (_error) {
          e = _error;
        }
        return;
      }
      if (thingToDestroy instanceof Folder) {
        processFolder(thingToDestroy);
        inFolders.unshift(thingToDestroy);
        inFolders.reverse();
        for (j = 0, len = inFiles.length; j < len; j++) {
          aFile = inFiles[j];
          try {
            aFile.remove();
          } catch (_error) {
            e = _error;
          }
        }
        for (k = 0, len1 = inFolders.length; k < len1; k++) {
          aFolder = inFolders[k];
          try {
            aFolder.remove();
          } catch (_error) {
            e = _error;
          }
        }
        return;
      }
    };

    /*
         * Delete recursively a File or Folder which CONTAINS a string,
         * e.g. recursivelyDeleteThing("this", "~/Desktop/TEST") will catch
         * "com.this.example" and so on and so forth
         * @param  {String} thingToDestroy What the File or Folder name should contain
         * @param  {String} startFolder    The start folder
     */
    recursivelyDeleteThingFromFolder = function(thingToDestroy, startFolder) {
      var aFile, aFolder, escapeRegExp, inFiles, inFolders, j, k, len, len1, matchString, processFolder, re;
      inFolders = [];
      inFiles = [];
      escapeRegExp = function(stringToGoIntoTheRegex) {
        if (stringToGoIntoTheRegex instanceof Folder) {
          stringToGoIntoTheRegex = stringToGoIntoTheRegex.name;
        }
        return stringToGoIntoTheRegex.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
      };
      processFolder = function(fold) {
        var aThing, fileList, j, len, results;
        fileList = fold.getFiles();
        results = [];
        for (j = 0, len = fileList.length; j < len; j++) {
          aThing = fileList[j];
          if (aThing instanceof Folder) {
            inFolders.push(aThing);
            results.push(processFolder(aThing));
          } else {
            results.push(inFiles.push(aThing));
          }
        }
        return results;
      };
      processFolder(Folder(startFolder));
      matchString = escapeRegExp(thingToDestroy);
      re = new RegExp(matchString, "gi");
      for (j = 0, len = inFiles.length; j < len; j++) {
        aFile = inFiles[j];
        if (aFile.name.match(re)) {
          aFile.remove();
        }
      }
      for (k = 0, len1 = inFolders.length; k < len1; k++) {
        aFolder = inFolders[k];
        if (aFolder.name.match(re)) {
          recursivelyDeleteThing(aFolder);
        }
      }
    };
  };

  PSInstaller.prototype.copy = function() {
    var allFiles, copyFiles, createRelativeFolder, destinationFolder, destinationPath, eachFolder, getFoldersList, ignoreRegExp, j, k, len, len1, panelsPath, pluginsPath, product, ref, ref1, results, saveFolder, scriptsPath, sourceFolder, that;
    that = this;

    /*
         * [createRelativeFolder description]
         * @param  {folder} destination   the destination Folder
         * @param  {folder} origin        the original, existing Folder
         * @param  {folder} base      the Folder used as a base
         * @return {folder} a new created folder in the destination
     */
    createRelativeFolder = function(destination, origin, base) {
      var destinationArray, destinationToWriteArray, destinationToWriteFolder, destinationToWriteString, originArray, originBaseArray;
      destinationArray = decodeURI(destination).toString().split('/');
      originArray = decodeURI(origin).toString().split('/');
      originBaseArray = decodeURI(base).toString().split('/');
      originArray.splice(0, originBaseArray.length);
      destinationToWriteArray = destinationArray.concat(originArray);
      destinationToWriteString = destinationToWriteArray.join('/');
      destinationToWriteFolder = Folder(destinationToWriteString);
      if (!destinationToWriteFolder.exists) {
        destinationToWriteFolder.create();
      }
      PSU.log("Created Folder:\t" + destinationToWriteFolder.fsName);
      if(!endsWith(destinationToWriteFolder.fsName,"Plug-Ins") || 
        !endsWith(destinationToWriteFolder.fsName,"Generator") ||
        !endsWith(destinationToWriteFolder.fsName,"extensions") ||
        !endsWith(destinationToWriteFolder.fsName,"Scripts"))
      {
        that.installedFolders.push("" + destinationToWriteFolder.fsName);
      }
        
      return destinationToWriteFolder;
    };

    /*
         * process the folder and fills the external
         * array of folders foldersList
         * @param  {folder} folder 
         * @return {void}
     */
    getFoldersList = function(folder) {
      var i, item, j, len, list;
      if (folder.constructor === String) {
        folder = new Folder(folder);
      }
      list = folder.getFiles();
      i = 0;
      for (j = 0, len = list.length; j < len; j++) {
        item = list[j];
        if (item instanceof Folder) {
          that.foldersList.push(item);
          PSU.log("Folder: " + item.fsName);
          getFoldersList(item);
        }
      }
    };

    /*
         * Copy Files to a Folder
         * @param  {array} files  Array of strings (File paths)
         * @param  {string} folder Folder path to copy to
         * @return {void}
     */
    copyFiles = function(files, folder) {
      var eachFile, file, filesList, j, k, len, len1, results;
      filesList = [];
      for (j = 0, len = files.length; j < len; j++) {
        file = files[j];
        filesList.push(decodeURI(file));
      }
      results = [];
      for (k = 0, len1 = filesList.length; k < len1; k++) {
        eachFile = filesList[k];
        if (File(eachFile).exists) {
          File(eachFile).copy(folder + "/" + (File(eachFile).name));

          /* For the uninstaller */
          that.installedFiles.push(folder + "/" + (File(eachFile).name));
          results.push(PSU.log("Copied:\t\t" + (File(eachFile).name)));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    /* Routine */
    ref = this.productsToInstall;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      product = ref[j];
      if (!G[product]) {
        PSU.log("\n" + product + " - Nothing to install\n");
        continue;
      }
      switch (product) {
        case "SCRIPT":
          scriptsPath = app.path + "/" + (localize('$$$/ScriptingSupport/InstalledScripts=Presets/Scripts'));
          destinationPath = scriptsPath + "/" + G.COMPANY + "/" + G.PRODUCT_NAME;
          break;
        case "FLASH_PANEL":
          panelsPath = (G.SYSTEM_INSTALL ? Folder.commonFiles : Folder.userData) + "/Adobe/CS" + (G.CURRENT_PS_VERSION - 7) + "ServiceManager/extensions";
          destinationPath = panelsPath + "/" + G.PRODUCT_ID;
          break;
        case "HTML_PANEL":
          panelsPath = (G.SYSTEM_INSTALL ? Folder.commonFiles : Folder.userData) + "/Adobe/" + (G.CURRENT_PS_VERSION === '14' ? 'CEPServiceManager4' : 'CEP') + "/extensions";
          destinationPath = panelsPath + "/" + G.PRODUCT_ID;
          break;
        case "MAC_PLUGIN":
          if ($.os.match(/windows/i)) {
            destinationPath = "";
            break;
          }
          if (G.SHARED_PLUGINS && G.CURRENT_PS_VERSION > 13) {
            pluginsPath = Folder.commonFiles + "/Adobe/" + (localize('$$$/private/Plugins/DefaultPluginFolder=Plug-Ins')) + "/CC";
          } else {
            pluginsPath = app.path + "/" + (localize('$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'));
          }
          destinationPath = pluginsPath + "/" + G.COMPANY;
          break;
        case "WIN_PLUGIN":
          if (!$.os.match(/windows/i)) {
            destinationPath = "";
            break;
          }
          if (G.SHARED_PLUGINS && G.CURRENT_PS_VERSION > 13) {
            pluginsPath = Folder.commonFiles + "/Adobe/" + (localize('$$$/private/Plugins/DefaultPluginFolder=Plug-Ins')) + "/CC";
          } else {
            pluginsPath = app.path + "/" + (localize('$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'));
          }
          destinationPath = pluginsPath + "/" + G.COMPANY;
          break;
        case "EXTRA":
          if (!$.os.match(/windows/i)) {
            destinationPath = "";
            break;
          }
          if (G.SHARED_PLUGINS && G.CURRENT_PS_VERSION > 13) {
            pluginsPath = Folder.commonFiles + "/Adobe/" + (localize('$$$/private/Plugins/DefaultPluginFolder=Plug-Ins')) + "/CC";
          } else {
            pluginsPath = app.path + "/" + (localize('$$$/private/Plugins/DefaultPluginFolder=Plug-Ins'));
          }
          destinationPath = pluginsPath + "/Generator/";
          /*if(!Folder(destinationPath).exists)
          {
            try{
              var genFolder = new Folder(destinationPath);
              genFolder.create();
            }
            catch(e)
            {
              alert("Couldn't Create Generator Folder. Please Re Run Installation in Photoshop Admin mode!");
              throw Error("Couldn't create Generator Folder. Please Re Run Installation in Photoshop Admin Mode");
            }
          }*/
      }
      if (destinationPath === "") {
        continue;
      }
      PSU.log("\n\nAdding " + product + "\n----------------------------\nDestination folder: " + (Folder(destinationPath).fsName));

      /* Create destination Folder */
      if (PSU.createFolder(destinationPath)) {
        PSU.log("Destination Folder successfully created.\n");
      } else {
        PSU.log("ERROR! Can't create destination folder.");
      }

      /* Create the Folder for the source from the string path */
      sourceFolder = Folder(G.CURRENT_PATH + "/" + G[product]);

      /* Create the Folder for the destination from the string path */
      destinationFolder = Folder(destinationPath);

      /* Reset the array containing all the folders to be created in the destination */
      this.foldersList = [];

      /* Fill the foldersList */
      PSU.log("List of Folders to be copied for the " + product + ":");

      /* Log is in the getFolderl */
      getFoldersList(sourceFolder);

      /* Add the root folder to the list */
      this.foldersList.unshift(sourceFolder);
      PSU.log("Folder: " + sourceFolder);

      /* Create Folders tree in destination */
      PSU.log("\nCreating Folders in destination and copying files:\n");

      /* RegExp for ignoring files to be copied */
      ignoreRegExp = G.IGNORE ? new RegExp(G.IGNORE.join("|"), "i") : new RegExp("$.");
      ref1 = this.foldersList;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        eachFolder = ref1[k];
        saveFolder = createRelativeFolder(destinationFolder, eachFolder, sourceFolder);
        allFiles = eachFolder.getFiles(function(f) {
          if (f instanceof Folder) {
            return false;
          } else {
            if ((f.name.match(ignoreRegExp)) != null) {
              return false;
            }
            return true;
          }
        });
        if (allFiles.length) {
          copyFiles(allFiles, saveFolder);
        }
      }
      results.push(PSU.log("\nEnded copying files for " + product + "."));
    }
    return results;
  };

  PSInstaller.prototype.wrapUp = function() {
    var logMsg = "Complete!";
    if(G.ENABLE_LOG)
    {
      logMsg += "\nAn installation LOG file has been created in:\n" + G.LOG_FILE;
      alert(logMsg);
    }
    alert("Restart Photoshop\nYou must restart the application in orded to use " + G.PRODUCT_NAME + ", thank you!");
    if (G.README) {
      return (File(G.CURRENT_PATH + "/" + G.README)).execute();
    }
  };

  PSInstaller.prototype.createUninstaller = function() {
    var uninstall, uninstaller;
    uninstall = function(files, folders) {
      var e, eachFile, eachFolder, file, folder, j, k, len, performInstallation, uninstallErrors;
      if (!(performInstallation = confirm(G.PRODUCT_NAME + " Version " + G.PRODUCT_VERSION + " Uninstaller\nAre you sure to remove " + G.PRODUCT_NAME + "?"))) {
        return;
      }
      uninstallErrors = false;
      G.LOG_FILE = G.LOG_FILE_PATH + "/" + G.PRODUCT_NAME + " Uninstaller.log";

      /* init the logging */
      PSU.init(G.LOG_FILE, true);
      PSU.log("=======================================\n " + (new Date()) + "\n \tCompany: " + G.COMPANY + "\n \tProduct: " + G.PRODUCT_NAME + "\n \tProduct version: " + G.PRODUCT_VERSION + "\n \tApp: " + BridgeTalk.appName + "\n \tApp Version: " + app.version + "\n \tOS: " + $.os + "\n \tLocale: " + $.locale + "\n ---------------------------------------\n \tInstaller Version: " + G.INSTALLER_VERSION + "\n =======================================");
      PSU.log("\nRemoving FILES...");
      for (j = 0, len = files.length; j < len; j++) {
        eachFile = files[j];
        try {
          file = File(eachFile);
          PSU.log("Removing:\t" + file.fsName + "...");
          file.remove();
          PSU.log("Done!");
        } catch (_error) {
          e = _error;
          PSU.log("ERROR!");
          uninstallErrors = true;
        }
      }
      PSU.log("---------------------------------------\n Removing FOLDERS...");
      for (k = folders.length - 1; k >= 0; k += -1) {
        eachFolder = folders[k];
        try {
          folder = Folder(eachFolder);
          if(endsWith(destinationToWriteFolder.fsName,"Plug-Ins") || 
              endsWith(destinationToWriteFolder.fsName,"Generator") ||
              endsWith(destinationToWriteFolder.fsName,"extensions") ||
              endsWith(destinationToWriteFolder.fsName,"Scripts")){
            continue;
          }
          PSU.log("Removing:\t" + folder.fsName + "...");
          folder.remove();
          PSU.log("Done!");
        } catch (_error) {
          e = _error;
          PSU.log("ERROR!");
          uninstallErrors = true;
        }
        if (uninstallErrors) {
          alert("Something went wrong!\nA uninstallation LOG file has been created in:\n" + G.LOG_FILE + ", please send it to " + G.CONTACT_INFO);
          throw Error("Restart Photoshop and see if the product has been uninstalled anyway.");
        }
      }
      return alert(G.PRODUCT_NAME + " successfully Removed\nPlease Restart Photoshop for the changes to take effect.");
    };
    uninstaller = new File(G.CURRENT_PATH + "/" + G.PRODUCT_NAME + "_V" + G.PRODUCT_VERSION + " - UNINSTALLER.jsx");
    if (!uninstaller.open('w')) {
      throwFileError(uninstaller, "Unable to Write the Uninstaller file");
    }
    if (PSU.isMac()) {
      uninstaller.lineFeed = 'unix';
    }
    uninstaller.writeln("var G = " + (G.toSource()));

    /* This won't work :-/
        uninstaller.writeln "var PSU = #{PSU.toSource()}"
     */
    uninstaller.writeln("var PSU=(function(GLOBAL){var createFolder,exceptionMessage,init,isMac,isWindows,log,that,throwFileError;that=this;this.enableLog=void 0;this.logFile=void 0;this.logFilePointer=void 0;isWindows=function(){return $.os.match(/windows/i);};isMac=function(){return!isWindows();};throwFileError=function(f,msg){if(msg==null){msg='';}return Error.runtimeError(9002,''+msg+''+f+': '+f.error+'.');};exceptionMessage=function(e){var fname,str;fname=!e.fileName?'???':decodeURI(e.fileName);str='  Message: '+e.message+'  File: '+fname+'\\tLine: '+(e.line||'???')+'\\n\\tError Name: '+e.name+'\\n\\tError Number: '+e.number;if($.stack){str+='  '+$.stack;}return str;};log=function(msg){var file;if(!that.enableLog){return;}file=that.logFilePointer;if(!file.open('e')){throwFileError(file,'Unable to open Log file');}file.seek(0,2);if(!file.writeln(''+msg)){return throwFileError(file,'Unable to write to log file');}};createFolder=function(fptr){var rc;if(fptr==null){Error.runtimeError(19,'No Folder name specified');}if(fptr.constructor===String){fptr=new Folder(fptr);}if(fptr instanceof File){return createFolder(fptr.parent);}if(fptr.exists){return true;}if(!(fptr instanceof Folder)){log(fptr.constructor);Error.runtimeError(21,'Folder is not a Folder?');}if((fptr.parent!=null)&&!fptr.parent.exists){if(!createFolder(fptr.parent)){return false;}}rc=fptr.create();if(!rc){Error.runtimeError(9002,'Unable to create folder '+fptr+' ('+fptr.error+') Please create it manually and run this script again.');}return rc;};init=function(logFile,isLogEnabled){var file;if(!isLogEnabled){return;}that.enableLog=isLogEnabled;that.logFile=logFile;file=new File(that.logFile);if(file.exists){file.remove();}if(!file.open('w')){throwFileError(file,'Unable to open Log file');}if(isMac()){file.lineFeed='unix';}that.logFilePointer=file;};return{'isMac':isMac,'exceptionMessage':exceptionMessage,'log':log,'createFolder':createFolder,'init':init};})(this);");
    uninstaller.writeln("var filesToRemove = " + (this.installedFiles.toSource()) + ";");
    uninstaller.writeln("var foldersToRemove = " + (this.installedFolders.toSource()) + ";");
    uninstaller.writeln("var uninstall = " + (uninstall.toSource()) + ";");
    uninstaller.writeln("uninstall(filesToRemove, foldersToRemove);");
    return uninstaller.close();
  };

  return PSInstaller;

})();

try {
  psInstaller = new PSInstaller();
  psInstaller.preflight();
  psInstaller.init();
  psInstaller.clean();
  psInstaller.copy();
  psInstaller.createUninstaller();
  psInstaller.wrapUp();
} catch (_error) {
  e = _error;
  errorMessage = "Installation failed: " + (PSU.exceptionMessage(e));
  PSU.log(errorMessage);
  alert("Something went wrong!\n" + errorMessage + "\nPlease contact " + G.CONTACT_INFO + ", thank you.");
}


/* EOF */

"psInstaller";
