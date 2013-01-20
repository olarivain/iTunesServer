require 'rubygems'
require 'xcodebuilder'

iTunesBuilder = XcodeBuilder::XcodeBuilder.new do |config|
  # basic workspace config
  config.build_dir = :derived
  config.workspace_file_path = "iTunesServer.xcworkspace"
  config.scheme = "iTunesServer"
  config.configuration = "Release" 
  config.app_name = "iTunesServer"
  config.sdk = "macosx"
  config.info_plist = "./iTunesServer/iTunesServer-Info.plist"
  config.skip_dsym = true
  config.skip_clean = false
  config.verbose = false
  config.increment_plist_version = true
  config.tag_vcs = true
  
  # tag and release with git
  config.release_using(:git) do |git|
    git.branch = "test"
  end
end

task :clean do
  # dump temp build folder
  FileUtils.rm_rf "./build"
  FileUtils.rm_rf "./pkg"

  # and cocoa pods artifacts
  FileUtils.rm_rf iTunesBuilder.configuration.workspace_file_path
  FileUtils.rm_rf "Podfile.lock"
end

# pod requires a full clean and runs pod install
task :pod => :clean do
  system "pod install"
end

task :package => :pod do
  iTunesBuilder.package
end

task :release => :pod do
  iTunesBuilder.release
end

# this task is 100% specific to my environment. Won't work for y'all.
task :macmini => :package do

  # copy the app/pref pane first
  puts "Deploying iTunesServer to MiniMoi.local"
  appArchiveName = "iTunesServer-#{iTunesBuilder.configuration.build_number}.zip"
  macMiniCmd = "scp -r target/#{appArchiveName} kra@MiniMoi.local:/Applications/ > /dev/null 2>&1"
  system macMiniCmd

  macMiniCmd = "scp -r target/iTunesServer-PrefPane-#{iTunesBuilder.configuration.build_number}.zip kra@MiniMoi.local:~/iTunesServerPrefPane/ > /dev/null 2>&1"
  system macMiniCmd
  
  # kill current running app, then remove existing bundle. 
  # Unzip new app bundle, and clean the mess: delete the .zip and the unfortunate dSYM file.
  # then, restart iTunesServer
  puts "Restarting iTunesServer App on MiniMoi.local"
  remoteCommand = "killall -9 iTunesServer; cd /Applications; rm -rf iTunesServer.app; unzip -o #{appArchiveName}; rm -rf iTunesServer.app.dSYM #{appArchiveName}; open iTunesServer.app"
  macMiniCmd = "ssh kra@MiniMoi.local '(#{remoteCommand}) > /dev/null 2>&1'"

  system macMiniCmd

end