require 'filesize'
require 'json'
require 'logger'
require 'open3'
require 'sinatra/base'
require 'yaml'

class GPFS
  def logger
    self.class.logger
  end
  def self.logger
    return @logger if @logger
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @logger
  end

  def self.filesystems
    [
      'project',
      'scratch',
    ]
  end

  def self.static_filesets
    {
      'scratch' => {'root' => Fileset.new('root', '/fs/scratch', 'root', 'root', '1775', nil, nil)}
    }
  end

  def self.proj_dir
    File.dirname(__FILE__)
  end

  def self.fileset_input(filesystem)
    if ! Sinatra::Base.production?
      File.join(self.proj_dir, "test/fixtures/#{filesystem}_filesets.yaml")      
    else
      "/users/reporting/storage/data/#{filesystem}_filesets.yaml"
    end    
  end

  def self.quota_input(filesystem)
    if ! Sinatra::Base.production?
      File.join(self.proj_dir, "test/fixtures/gpfs.#{filesystem}_quota.json")
    else
      "/users/reporting/storage/quota/gpfs.#{filesystem}_quota.json"
    end
  end

  Fileset = Struct.new(:name, :path, :user, :group, :permissions, :block_limit, :file_limit)
  FilesetQuota = Struct.new(:name, :block_usage, :block_limit, :block_percent_used, :file_usage, :file_limit, :file_percent_used)
  UserQuota = Struct.new(:username, :block_usage, :block_percent_used, :file_usage, :file_percent_used)

  attr_accessor :filesets

  def initialize(filesystem)
    @filesystem = filesystem
    @fileset_data = load_fileset_data(filesystem)
    @filesets = parse_filesets(@fileset_data, filesystem)
  end

  def load_fileset_data(filesystem)
    path = self.class.fileset_input(filesystem)
    if ! File.exist?(path)
      return {}
    end
    File.open(path, 'r') do |f|
      if path == '.marshall'
        data = Marshal.load(f)
      else
        data = YAML.load(f)
      end
    end
  end

  def load_quota_data(filesystem)
    path = self.class.quota_input(filesystem)
    if ! File.exist?(path)
      return {}
    end
    File.open(path, 'r') do |f|
      data = JSON.load(f)
    end
  end

  def parse_filesets(data, filesystem)
    return self.class.static_filesets[filesystem] if self.class.static_filesets.key?(filesystem)
    filesets = {}
    data.each_pair do |name, d|
      owner = d['owner'].split(':')
      path = File.join('/fs', filesystem, name)
      user = owner[0]
      group =  owner[1]
      perms =  d['permissions']
      quota = d.fetch('quota', {})
      block = quota['block_hard_limit']
      files = quota['files_hard_limit']
      if block
        block_regex = /^([0-9\.]+)(T|G)/
        block_size = block[block_regex, 1]
        block_unit = block[block_regex, 2]
        block = Filesize.from("#{block_size} #{block_unit}iB")
      end
      fileset = Fileset.new(name, path, user, group, perms, block, files)
      filesets[name] = fileset
    end
    filesets
  end

  def fileset_quota(fileset)
    @quota_data ||= load_quota_data(@filesystem)
    @fileset_quota = parse_fileset_quota(fileset, @quota_data.fetch('quotas_other', []))
    @fileset_quota
  end

  def user_quotas(fileset)
    @quota_data ||= load_quota_data(@filesystem)
    @fileset_quota ||= fileset_quota(fileset)
    @user_quotas = parse_user_quotas(fileset, @fileset_quota, @quota_data.fetch('quotas', []))
    @user_quotas
  end

  def parse_fileset_quota(fileset_name, data)
    quota = FilesetQuota.new(fileset_name, nil, nil, nil, nil, nil, nil)
    return quota if data.nil? || data.empty?
    fileset = @filesets[fileset_name]
    data.each do |d|
      name = d['group']
      next unless name == fileset_name
      block_usage = Filesize.from("#{d['total_block_usage']} KiB")
      file_usage = d['total_file_usage']
      if fileset.nil?
        logger.error "#{__method__}: fileset #{name} not found"
        return FilesetQuota.new(name, block_usage, nil, nil, file_usage, nil, nil)
      end
      block_limit = fileset.block_limit
      file_limit = fileset.file_limit
      if block_limit.nil? || block_limit == 0
        block_percent = 'NA'
      else
        block_percent = ( block_usage / block_limit ) * 100.0
      end
      if file_limit.nil? || file_limit == 0
        file_percent = 'NA'
      else
        file_percent = ( file_usage.to_f / file_limit.to_f ) * 100.0
      end
      #logger.info("Fileset=#{fileset_name} Filelimit=#{file_limit} FileUsage=#{file_usage} Percet=#{file_percent}")
      quota = FilesetQuota.new(name, block_usage, block_limit, block_percent, file_usage, file_limit, file_percent)
      return quota
    end
    return quota
  end

  def parse_user_quotas(fileset_name, fileset_quota, data)
    return [] if data.nil?
    quotas = []
    fileset = @filesets[fileset_name]
    data.each do |d|
      username = d['user']
      path = d['path']
      if fileset && path != fileset.path
        next
      end
      if d['block_usage'] < 0
        d['block_usage'] = 0
      end
      block_usage = Filesize.from("#{d['block_usage']} KiB")
      file_usage = d['file_usage']
      block_limit = fileset_quota.block_limit
      file_limit = fileset_quota.file_limit
      if block_limit.nil? || block_limit == 0
        block_percent = 'NA'
      else
        block_percent = ( block_usage / block_limit ) * 100.0
      end
      if file_limit.nil? || file_limit == 0
        file_percent = 'NA'
      else
        file_percent = ( file_usage.to_f / file_limit.to_f ) * 100.0
      end
      #logger.info("Fileset=#{fileset_name} Filelimit=#{file_limit} FileUsage=#{file_usage} Percet=#{file_percent}")
      quota = UserQuota.new(username, block_usage, block_percent, file_usage, file_percent)
      quotas << quota
    end
    quotas
  end
end
