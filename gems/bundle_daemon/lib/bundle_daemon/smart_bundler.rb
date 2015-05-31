require 'pathname'
require 'fileutils'
require 'digest'
require 'logger'
require 'open3'


module BundleDaemon
  class SmartBundler
    GEMFILE_PATS = [/gemfile$/i, /gemspec$/i]

    attr_reader :cache_folder
    attr_writer :logger

    def initialize(cache_folder = '~/.gem/smart_bundler/')
      @logger = nil
      FileUtils.mkdir_p cache_folder
      @cache_folder = cache_folder
    end

    def logger
      @logger ||= Logger.new(STDOUT)
      @logger
    end


    def work_dir(gemfile_path)
      pn = Pathname.new(gemfile_path)

      GEMFILE_PATS.each do |pat|
        if pn.basename.to_s =~ pat
          return pn.dirname.to_s
        end
      end

      raise(ArgumentError, "#{gemfile_path} does not match any know gemfile pattern.")
    end

    def with_new_wd(path)
      new_dir = work_dir(path)
      old_dir = Dir.pwd

      Dir.chdir(new_dir)
      logger.info("Working dir set to #{new_dir}")

      yield new_dir

      Dir.chdir(old_dir)
      logger.info("Working dir set to #{old_dir}")
    end

    def with_bundler_safe_env
      prev_gemfile = ENV['BUNDLE_GEMFILE']
      prev_bin = ENV['BUNDLE_BIN_PATH']
      prev_opt = ENV['RUBYOPT']

      ENV['BUNDLE_GEMFILE'] = nil
      ENV['BUNDLE_BIN_PATH'] = nil
      ENV['RUBYOPT']=nil

      yield

      ENV['BUNDLE_GEMFILE'] = prev_gemfile
      ENV['BUNDLE_BIN_PATH'] = prev_bin
      ENV['RUBYOPT']=prev_opt

    end


    def current_md5_for(filename)
      Digest::MD5.file(filename).hexdigest
    end

    def cache_file_name(filename)
      "#{filename.gsub(/\/|\\|\:/, '_')}.md5"
    end

    def cached_md5_for(filename)
      cache_file = cache_file_path(filename)
      return File.read(cache_file) if File.exist?(cache_file)
      nil
    end

    def cache_file_path(filename)
      File.join(@cache_folder, cache_file_name(filename))
    end

    def save_md5_for(filename)
      File.open(cache_file_path(filename), 'w') { |file| file.write(current_md5_for(filename))}
    end

    def need_bundle?(filename)
      (cached_md5_for(filename) != current_md5_for(filename)) || !File.exist?("#{filename}.lock")
    end


    def bundle_install(gemfile_path)
      logger.info("Install in #{gemfile_path}")
      return true unless need_bundle?(gemfile_path)

      with_new_wd(gemfile_path) do |new_dir|

        logger.info("Performing bundle install in #{new_dir}")
        status = ''

        with_bundler_safe_env do
          stdout, stderr, status = Open3.capture3("bundle install --no-cache --gemfile #{gemfile_path}")
          logger.error("\n\n#{stdout}\n\n#{stderr}\n") unless status.success?
        end

        logger.error("Bundle install failed in #{new_dir}") unless status.success?

        logger.info("Bundle install in #{new_dir} done") if status.success?
        status.success?
      end

    end


  end
end
