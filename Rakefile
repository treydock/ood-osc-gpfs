begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

PROJ_DIR = File.dirname __FILE__

desc "Install depedencies"
task :build do
  if ENV["RACK_ENV"] == "production"
    bundle_args = "--without test development"
  else
    bundle_args = ""
  end

  chdir PROJ_DIR do
    sh "bundle install #{bundle_args}"
  end
end

desc "Clean project"
task :clean do
  chdir PROJ_DIR do
    sh "git clean -Xfd"
  end
end
