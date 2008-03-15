desc "Usage: rake freeze gem=GEMNAME [version=VERSION]\n                                 freeze gem to vendor/plugins"
task :freeze do
  gemname = ENV['gem']
  version = ENV['version']
  tmp_dir = Dir::tmpdir
  Gem.manage_gems
  if gemname.nil?
    puts "ERROR. No gem name given."
    puts "Usage: rake freeze gem=GEMNAME [version=VERSION]"
    exit(1)
  end
  gem = if version
          Gem.cache.search(gemname, "= #{version}").first
        else
          Gem.cache.search(gemname).sort_by { |g| g.version }.last
        end
  if gem.nil?
    begin
      if version.nil?
        Gem::GemRunner.new.run ["install", "#{gemname}", "-i", "#{tmp_dir}/gems", "--no-rdoc", "--include-dependencies"]
      else
        Gem::GemRunner.new.run ["install", "#{gemname}", "-v", "#{version}", "-i", "#{tmp_dir}/gems", "--no-rdoc", "--include-dependencies"]
      end
    rescue
      puts "ERROR. Failed to download #{gemname}."
      exit(1)
    end
    ENV["GEM_HOME"] = "#{tmp_dir}/gems"
    gem = Gem::SourceIndex.from_installed_gems("#{tmp_dir}/gems/specifications").search(gemname).first
  end
  begin
    gem.dependencies.each do |g|
      chdir("vendor/plugins") do
        Gem::GemRunner.new.run ["unpack", "-v", "#{g.version_requirements}", g.name ]
      end
    end
    chdir("vendor/plugins") do
      Gem::GemRunner.new.run ["unpack", "-v", "=#{gem.version}", gemname ]
    end
  rescue
    puts "ERROR. Failed to unpack #{gemname}."
    exit(1)
  end
  puts "SUCCESS."
end