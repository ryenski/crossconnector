desc "Checkin your changes after running the tests"
Rake::TestTask.new(:changed => [ :prepare_test_database ]) do |t|
  info = `svn info`
  since = Time.parse(info[/Last Changed Date: .*/])
  touched = FileList['test/**/*_test.rb'].select { |path| File.mtime(path) > since } +
    recent_tests('app/models/*.rb', 'test/unit', since) +
    recent_tests('app/controllers/*.rb', 'test/functional', since)

  t.libs << 'test'
  t.verbose = true
  t.test_files = touched.uniq
end

desc "Check-in work"
task :ci do
  exec("rake", "setup_svn") if `which svnorig`[/no svnorig/]

  tests = `rake changed`
  puts tests
  exec("svnorig", *YAML::load(ENV['MESSAGE'])) unless tests[/rake aborted/]
end

desc "Install subversion alias"
task :setup_svn do
  svn = `which svn`.strip
  exec("sudo mv #{svn} #{svn}orig && sudo ln -s #{File.expand_path(RAILS_ROOT)}/bin/svn #{svn} && echo 'All set, use svn ci as you normally would'")
end


# From: 
# http://tech.rufy.com/articles/2006/01/20/prevent-yourself-from-writing-bad-code
# 
# To initialize this process, and you only have to do this once per machine 
# you use it on, you simply type:
# rake setup_svn
#
# When prompted by sudo, type your user password and you are done.
#
# Now, whenever you are in a Rails root directory and the file 
# lib/tasks/svn.rake exists, svn ci does the following:
#   * Find all files that you have touched since the last commit
#   * Run and show the unit tests of all of those files
#
# If the unit tests pass, commit the changes as expected
# If the unit tests fail, exit
#
# This all assumes that you have been good and wrote solid unit tests, but as the good programmer I know you are, that should be a valid assumption. Enjoy!