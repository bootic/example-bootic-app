require 'bundler/setup'
require 'omniauth-bootic'
require 'sinatra'
require 'bootic_client'

unless File.exist?('config.yml')
  abort "config.yml missing. Please copy config.yml.example to config.yml and insert keys."
end

CONFIG = YAML.load_file('./config.yml')

class ExampleApp < Sinatra::Base

  def initialize
    BooticClient.configure do |c|
      c.client_id     = CONFIG[:bootic_key]
      c.client_secret = CONFIG[:bootic_secret]
      c.logger        = Logger.new(STDOUT)
      # c.cache_store = Rails.cache
    end

    super
  end

  set :views, './views'
  set :sessions, true

  use OmniAuth::Builder do
    provider(:bootic, CONFIG[:bootic_key], CONFIG[:bootic_secret], { scope: 'public,admin' })
  end

  helpers do
    def current_shop
      @current_shop ||= root.shops.first
    end

    def root
      @root ||= client.root
    end

    def client
      @client ||= BooticClient.client(:authorized, access_token: session[:access_token]) do |new_token|
        session[:access_token] = new_token
      end
    end

    def user_email
      session[:auth_info][:email]
    end

    def logged_in?
      !!session[:access_token]
    end
  end

  error do
    err = request.env['sinatra.error']
    logger.error err.message
    logger.error err.backtrace.first(3).join("\n")
    halt(500, err.message)
  end

  get '/' do
    if logged_in?
      redirect to('/admin')
    else
      erb :login
    end
  end

  get '/admin' do
    if logged_in?
      erb :admin
    else
      redirect to('/')
    end
  end

  get '/logout' do
    session.delete(:access_token)
    session.delete(:auth_info)
    redirect to('/')
  end

  get '/auth/:provider/callback' do
    auth   = request.env['omniauth.auth']
    params = request.env['omniauth.params']

    session[:auth_info]    = { email: auth['info']['email'] } 
    session[:access_token] = auth['credentials']['token'] or raise "No credentials/token!"

    redirect to('/')
  end

  get '/auth/failure' do
    redirect to('/login?error=oauth2_fail')
  end

end