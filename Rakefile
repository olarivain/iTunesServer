require 'rubygems'
require 'xcodebuilder'

workspace_path = "iTunesServer.xcworkspace"

task :clean do
  # dump temp build folder
  FileUtils.rm_rf "./build"
  FileUtils.rm_rf "./pkg"

  # and cocoa pods artifacts
  FileUtils.rm_rf workspace_path
  FileUtils.rm_rf "Podfile.lock"
end

# pod requires a full clean and runs pod install
task :pod => :clean do
  system "pod install"
end

task :build  do
  builder = XcodeBuilder::XcodeBuilder.new do |config|
    # basic workspace config
    config.build_dir = :derived
    config.workspace_file_path = workspace_path
    config.scheme = "iTunesServer"
    config.configuration = "Release" 
    config.app_name = "iTunesServer"
    config.info_plist = "./Resources/Info.plist"
    config.skip_dsym = true
    config.skip_clean = false
    config.verbose = false
    config.increment_plist_version = true
    config.tag_vcs = true
    config.sdk = "macosx"

    config.skip_version_increment = false
    config.skip_scm_tagging = false

    # tag and release with git
    config.release_using(:git) do |git|
      git.branch = "test"
    end
  end

  builder.package
end

# raven = Raven.new()

# task :clean do
# 	raven.clean
# end

# task :resolve do
# 	raven.resolve
# end

# task :build, :configuration do |task, arg|
# 	raven.build(arg.configuration)
# end

# task :install do
# 	raven.install
# end

# task :release do
# 	raven.release
# end

# this task is 100% specific to my environment. Won't work for y'all.
# task :macmini do
#   raven.clean
#   raven.build
#   raven.install
#   # copy the app/pref pane first
#   puts "Deploying iTunesServer to MiniMoi.local"
#   appArchiveName = "iTunesServer-#{raven.version}.zip"
#   macMiniCmd = "scp -r target/#{appArchiveName} kra@MiniMoi.local:/Applications/ > /dev/null 2>&1"
#   system macMiniCmd

#   macMiniCmd = "scp -r target/iTunesServer-PrefPane-#{raven.version}.zip kra@MiniMoi.local:~/iTunesServerPrefPane/ > /dev/null 2>&1"
#   system macMiniCmd
  
#   # kill current running app, then remove existing bundle. 
#   # Unzip new app bundle, and clean the mess: delete the .zip and the unfortunate dSYM file.
#   # then, restart iTunesServer
#   puts "Restarting iTunesServer App on MiniMoi.local"
#   remoteCommand = "killall -9 iTunesServer; cd /Applications; rm -rf iTunesServer.app; unzip -o #{appArchiveName}; rm -rf iTunesServer.app.dSYM #{appArchiveName}; open iTunesServer.app"
#   macMiniCmd = "ssh kra@MiniMoi.local '(#{remoteCommand}) > /dev/null 2>&1'"

#   system macMiniCmd

# end