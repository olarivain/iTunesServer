require 'XCodeDeployer'
require 'XCodeProduct'

name = "iTunesServer"
prefPaneName = "iTunes Server"

appServer = XCodeProduct.new("#{name}.app", name, "Release", ["macosx"], false)
prefPane = XCodeProduct.new("#{prefPaneName}.prefPane", "#{name}PrefPane", "Release", ["macosx"], false)

products = [appServer]
allProducts = [appServer, prefPane];

builder = XCodeDeployer.new(products)
allBuilders = XCodeDeployer.new(allProducts, true)

task :setup do
	builder.setup
end

task :default => [:build, :deploy] do
end

task :clean do
	puts "cleaning " + name
	builder.clean
end

task :build do
	puts "building " + name
	builder.build
end

task :install do
	puts "Deploying " + name
	builder.deploy
end

task :release => [:setup, :clean, :build, :deploy] do
	builder.release
end

task :deploy do
  allBuilders.clean
  allBuilders.build
  allBuilders.deploy
	macMiniCmd = "scp -r /usr/local/xcodeproducts/#{name}/LATEST/#{name}.app kra@MiniMoi.local:/Applications/"
	system macMiniCmd
  macMiniCmd = "scp -r \"/usr/local/xcodeproducts/iTunesServerPrefPane/LATEST/#{prefPaneName}.prefPane\" kra@MiniMoi.local:~/"
	system macMiniCmd
end

task :sdef do
  builder.clean
  builder.build
  builder.deploy
  system "sdef /usr/local/xcodeproducts/iTunesServer/LATEST/iTunesServer.app/ | sdp -fh --basename iTunesServer -o iTunesServerPrefPane"
end