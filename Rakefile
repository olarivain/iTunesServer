require 'XCodeDeployer'
require 'XCodeProduct'

name = "iTunesServer"
products = [XCodeProduct.new("#{name}.app", name, "Release", ["macosx"], false)]
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
	macMiniCmd = "scp -r /usr/local/xcodeproducts/#{name}/LATEST/#{name}.app kra@MiniMoi.local:/Applications/"
	system macMiniCmd
end

