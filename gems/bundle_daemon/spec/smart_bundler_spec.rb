require 'spec_helper'
require 'fileutils'

module BundleDaemon
  TEST_GEMFILE_MD5 = '4f6f7ba88be0d29fdb7b955dc341f593'

  describe SmartBundler do

    before(:each) {
      @cache_dir = '~/.gem/sb_test'
      @test_data_dir = File.join( Dir.pwd, 'spec/test_data')
      @gemfile = "#{@test_data_dir}/gemfile"
      @gemfile_lock = "#{@test_data_dir}/gemfile.lock"
    }

    after(:each) {
      @cache_dir = '~/.gem/sb_test'
      FileUtils.rm_rf(@cache_dir) if Dir.exists?(@cache_dir)
    }

    it 'has a version number' do
      expect(BundleDaemon::VERSION).not_to be nil
    end

    it 'has a default cache folder' do
      sb = SmartBundler.new

      expect(sb.cache_folder).to_not be_nil
    end

    it 'accepts a custom cache folder' do
      sb = SmartBundler.new (@cache_dir)

      expect(sb.cache_folder).to eq @cache_dir
    end

    it "creates the work folder if it doesn't exist" do
      FileUtils.rm_rf( @cache_dir) if Dir.exists?( @cache_dir)
      SmartBundler.new ( @cache_dir)
      expect(Dir.exists?( @cache_dir)).to be true
    end

    it 'returns a working dir for a gemfile' do
      sb = SmartBundler.new (@cache_dir)
      expect(sb.work_dir("#{@cache_dir}/gemfile")).to eq(@cache_dir)
    end

    it 'will raise an raise ArgumentError for a non-gemfile' do
      sb = SmartBundler.new (@cache_dir)
      expect{ sb.work_dir("#{@cache_dir}/foobar")}.to raise_error(ArgumentError)
    end

    it 'safely changes the working directory given a gemfile' do
      sb = SmartBundler.new (@cache_dir)
      old_dir = Dir.pwd

      sb.with_new_wd(@gemfile) do
        expect {Dir.pwd.to eq(@cache_dir)}
      end

      expect {Dir.pwd.to eq(old_dir)}
    end

    it 'calculates a hash for the gemfile' do
      sb = SmartBundler.new (@cache_dir)
      expect( sb.current_md5_for(@gemfile)).to eq TEST_GEMFILE_MD5
    end

    it 'generates a cache filename based off the gemfile' do
      sb = SmartBundler.new (@cache_dir)
      sb.cache_file_path(@gemfile).should =~ /_spec_test_data_gemfile.md5$/
    end

    it 'saves the gemfile hash to a cache file' do
      sb = SmartBundler.new (@cache_dir)
      sb.save_md5_for(@gemfile)
      File.exists?(sb.cache_file_path(@gemfile)).should be true
      FileUtils.rm_rf(sb.cache_file_path(@gemfile)) if File.exists?(sb.cache_file_path(@gemfile))
    end

    it 'reads gemfile hash from a cache file' do
      sb = SmartBundler.new (@cache_dir)
      sb.save_md5_for(@gemfile)

      expect(sb.cached_md5_for(@gemfile)).to eq sb.current_md5_for(@gemfile)
      FileUtils.rm_rf(sb.cache_file_path(@gemfile)) if File.exists?(sb.cache_file_path(@gemfile))
    end


    it 'knows if it needs to run bundler' do
      sb = SmartBundler.new (@cache_dir)


      FileUtils.rm_rf(sb.cache_file_path(@gemfile)) if File.exists?(sb.cache_file_path(@gemfile))

      # No cache file?  Need a bundle
      expect( sb.need_bundle?(@gemfile) ).to be true

      # Have cache and lock file?  No bundle
      sb.save_md5_for(@gemfile)
      FileUtils.touch @gemfile_lock
      expect( sb.need_bundle?(@gemfile) ).to be false

      # No lock file but have a cache?  Need a bundle
      FileUtils.rm_rf(@gemfile_lock) if File.exists?(@gemfile_lock)
      expect( sb.need_bundle?(@gemfile) ).to be true

      FileUtils.rm_rf(sb.cache_file_path(@gemfile)) if File.exists?(sb.cache_file_path(@gemfile))
    end

    it 'performs a bundle install' do
      sb = SmartBundler.new (@cache_dir)

      FileUtils.rm_rf(sb.cache_file_path(@gemfile)) if File.exists?(sb.cache_file_path(@gemfile))

      sb.bundle_install(@gemfile)

      expect( File.exists?(@gemfile_lock) ).to be true
      FileUtils.rm_rf(@gemfile_lock) if File.exists?(@gemfile_lock)
    end

  end

end
