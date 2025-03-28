import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'dart:io';


class FileUtils{
  static String? getHomeDirectory(){
    String? home = "";
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS) {
      home = envVars['HOME'];
    } else if (Platform.isLinux) {
      home = envVars['HOME'];
    } else if (Platform.isWindows) {
      home = envVars['UserProfile'];
    }
    return home;
  }

  static String getApplicationDirectory(){
    return "${getHomeDirectory()}/noita-mod-manager";
  }

  static Future<List<String>> findNoitaDirectory() async{
    List<String> gamePaths = List.empty(growable: true);
    var home = getHomeDirectory();
    if(Platform.isLinux || Platform.isMacOS){
      var linuxPaths = [
        "$home/.steam/steam/steamapps/common/Noita",
        "$home/.local/share/Steam/steamapps/common/Noita/" //somewhat older form under .local/share
        //TODO is there a likely default for GOG installs?
      ];
      for (var p in linuxPaths) {
        if(File(p).existsSync()) {
          gamePaths.add(p);
        }
      }
    }
    else if(Platform.isWindows){
      var steamResult = await Process.run("powershell.exe", [
        "(Get-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App 881100\").GetValue(\"InstallLocation\")"
      ]);
      if(steamResult.stdout != ""){
        gamePaths.add(steamResult.stdout);
      }
      var gogResult = await Process.run("powershell.exe", [
        "(Get-Item \"HKLM:\\SOFTWARE\\WOW6432Node\\GOG.com\\Games\\1310457090\").GetValue(\"path\")"
      ]);
      if(gogResult.stdout != ""){
        gamePaths.add(gogResult.stdout);
      }
    }
    return gamePaths;
  }

  static String? getNoitaPrefsFolder(){
    var homeDir = getHomeDirectory();
    var folder = "$homeDir\\AppData\\LocalLow\\Nolla_Games_Noita";
    return folder;
  }

  static List<String> getSavedPaths(){
    var folder = getApplicationDirectory();
    var executablesPrefs = "$folder/data.txt";
    var contents = List<String>.empty(growable: true);
    try{
      contents = File(executablesPrefs).readAsLinesSync();
    }
    catch(ex){
      // ignore :3
    }
    return contents;
  }

  static String? getCurrentGamePath(){
    var paths = getSavedPaths();
    if(paths.isNotEmpty) return paths[0];
    return null;
  }

  static bool savePath(String path){
    var folder = getApplicationDirectory();
    var executablesPrefs = "$folder/data.txt";
    var contents = List<String>.empty(growable: true);
    try{
      contents = File(executablesPrefs).readAsLinesSync();
    }
    catch(ex){
      //ignore :3
    }
    if(contents.contains(path)) contents.remove(path);
    contents.insert(0, path);
    var file = File(executablesPrefs);
    try {
      file.createSync(recursive: true);
      file.writeAsStringSync(contents.join("\n"), flush: true, mode: FileMode.write);
    } catch (e) {
      //failed to save :(
      return false;
    }
    return true;
  }
}