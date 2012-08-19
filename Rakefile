require 'rubygems'
require 'Raven'
require 'RavenArtifact'


raven = Raven.new()

task :clean do
	raven.clean
end

task :resolve do
	raven.resolve
end

task :build, :configuration do |task, arg|
	raven.build(arg.configuration)
end

task :install do
	raven.install
end

task :release do
	raven.release
end

# this task is 100% specific to my environment. Won't work for y'all.
task :macmini do
  raven.clean
  raven.build
  raven.install
  # copy the app/pref pane first
  puts "Deploying iTunesServer to MiniMoi.local"
  appArchiveName = "iTunesServer-#{raven.version}.zip"
  macMiniCmd = "scp -r target/#{appArchiveName} kra@MiniMoi.local:/Applications/ > /dev/null 2>&1"
  system macMiniCmd

  macMiniCmd = "scp -r target/iTunesServer-PrefPane-#{raven.version}.zip kra@MiniMoi.local:~/iTunesServerPrefPane/ > /dev/null 2>&1"
  system macMiniCmd
  
  # kill current running app, then remove existing bundle. 
  # Unzip new app bundle, and clean the mess: delete the .zip and the unfortunate dSYM file.
  # then, restart iTunesServer
  puts "Restarting iTunesServer App on MiniMoi.local"
  remoteCommand = "killall -9 iTunesServer; cd /Applications; rm -rf iTunesServer.app; unzip -o #{appArchiveName}; rm -rf iTunesServer.app.dSYM #{appArchiveName}; open iTunesServer.app"
  macMiniCmd = "ssh kra@MiniMoi.local '(#{remoteCommand}) > /dev/null 2>&1'"

  system macMiniCmd

end