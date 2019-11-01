require 'erubi'
require 'logger'
require 'sinatra/base'
require 'sinatra/custom_logger'
require 'sinatra/reloader'
require './gpfs'

class App < Sinatra::Base
  set :erb, :escape_html => true

  configure :development do
    register Sinatra::Reloader
  end

  configure :development, :production do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    set :logger, logger
  end

  if development?
    also_reload './gpfs.rb'
  end

  helpers Sinatra::CustomLogger
  helpers do
    def dashboard_title
      "Open OnDemand"
    end

    def dashboard_url
      "/pun/sys/dashboard/"
    end

    def title
      "OSC GPFS Allocations"
    end

    def pretty(value)
      return 'NA' if value.nil?
      return value if value.is_a?(String)
      return value.pretty if value.is_a?(Filesize)
      if value.is_a?(Integer)
        return value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      elsif value.is_a?(Float)
        value.round(2)
      end
    end

    def request_path_parent(path)
      path_parts = path.split('/')[0...-1]
      #logger.info("DEBUG=#{path_parts}")
      path_parts.join('/')
    end

    def breadcrumbs
      path = request.path_info.to_s
      page = path.split('/')[-1]
      html = '<ol class="breadcrumb">'
      html = ["<li class=\"breadcrumb-item active\" aria-current=\"page\">#{page}</li>"]
      path = request_path_parent(path)
      #logger.info("PATH=#{path}")
      #return 'html'
      while path != '' do
        logger.info("PATH=#{path}")
        page = path.split('/')[-1]
        link = "<a href=\"#{url(path)}\">#{page}</a>"
        h = "<li class=\"breadcrumb-item\">#{link}</li>"
        html.prepend h
        path = request_path_parent(path)
      end
      html.prepend "<li class=\"breadcrumb-item\"><a href=\"#{url('/')}\">Home</a></li>"
      html.prepend '<ol class="breadcrumb">'
      html.append "</ol>"
      return html.join("\n")
=begin
      path_parts = path.split('/')
      path_parts.each_with_index do |p,i|
        if (i+1) == path_parts.size
          active = 'active'
          current = 'aria-current="page"'
          link = p
        else
          active = ''
          current = ''
          p_path_prefix = path.split(p)[1...-1]
          p_path = "#{p_path_prefix.join('/')}/#{p}"
          link = "<a href=\"#{url(p_path)}\">#{p}</a>"
        end
        h = "<li class=\"breadcrumb-item #{active}\" #{current}>#{link}</li>"
        html = html + h
      end
      html = html + "</ol>"
      html
=end
    end
  end

  # Define a route at the root '/' of the app.
  get '/' do
    @filesystems = GPFS.filesystems

    # Render the view
    erb :index
  end

  get '/:filesystem' do
    @filesystem = params[:filesystem]
    @gpfs = GPFS.new(@filesystem)
    @filesets = @gpfs.filesets

    erb :filesystem
  end

  get '/:filesystem/:fileset' do
    @filesystem = params[:filesystem]
    @fileset = params[:fileset]

    @gpfs = GPFS.new(@filesystem)
    @fileset_quota = @gpfs.fileset_quota(@fileset)
    logger.info("fileset=#{@fileset} quota=#{@fileset_quota}")
    @user_quotas = @gpfs.user_quotas(@fileset)

    erb :fileset
  end

end
