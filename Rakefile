require 'XCodeDeployer'
require 'XCodeProduct'

name = "CLIServer"
products = [XCodeProduct.new(name, name, "Release", ["macosx"], false)]
builder = XCodeDeployer.new(products)

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

task :deploy do
	puts "Deploying " + name
	builder.deploy
end

task :release => [:setup, :clean, :build, :deploy] do
	builder.release
end

task :macmini => [:release] do
	builder.release
	macMiniCmd = "scp /usr/local/xcodeproducts/CLIServer/LATEST/CLIServer kra@MiniMoi.local:/usr/local/bin/"
	system macMiniCmd
end

