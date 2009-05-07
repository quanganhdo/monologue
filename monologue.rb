require 'rubygems'
require 'sinatra'
require 'haml'
require 'active_record'
require 'digest/md5'
require 'logger'

mime :json, "application/json"

# prepare for battle
configure do 
  EMO = %w{cry misdoubt rockn_roll smile unhappy wicked}
  DEFAULT_EMO = 'misdoubt'
  
  SECRET = 'whatever happened, happened'
  
  db_config = YAML.load(File.read('config/database.yml'))
  CONNECTION = development? ? db_config['development'] : db_config['production']
  ActiveRecord::Base.establish_connection CONNECTION
  ActiveRecord::Base.logger = Logger.new(STDERR) if ENV['DEBUG']
  
  acc_config = YAML.load(File.read('config/account.yml'))
  ACCOUNT = development? ? acc_config['development'] : acc_config['production']
  
  begin
    ActiveRecord::Schema.define do
      create_table :posts do |t|
        t.text :content, :null => false
        t.string :emo, :null => false, :default => DEFAULT_EMO
        t.timestamps
      end
    end
  rescue ActiveRecord::StatementInvalid
      # do nothing
  end
end

# model
class Post < ActiveRecord::Base
  validates_presence_of :content
  validates_inclusion_of :emo, :in => EMO
  validate_on_create :valid_time?
  
  private
  
  def valid_time?
    @last_post = Post.find(:first, :order => 'created_at DESC')
    if @last_post && days_ago(@last_post.created_at) < 1 
      # this has nothing to do w/ content
      errors.add :content
    end
  end
end

# lock everything
before do
  protected!
  @count = Post.count
end

# entry point
# redirect to post listing if post of the day has been made
# otherwise, show new post form
['/', '/new'].each do |path|
  get path do
    @last_post = Post.find(:first, :order => 'created_at DESC')
    
    if !@last_post || days_ago(@last_post.created_at) >= 1
      haml :new, :layout => false
    elsif request.referer != '/'
      haml :already, :layout => false
    else
      redirect '/home'
    end
  end
end

# create a new post
post '/new' do
  post = Post.new(:content => params[:content].gsub(/\n/, ' '), :emo => params[:emo])

  if post.save
    redirect '/home'
  else
    redirect '/'
  end
end

# post listing
# show 7 latest posts
get '/home' do
  @posts = Post.find(:all, :limit => 7, :order => 'created_at DESC')
  @listing = 'Latest Updates'
  
  haml :listing
end

# permalink to specific post
get '/:id' do
  pass unless params[:id] =~ /^[0-9]*$/
  
  begin
    @post = Post.find(params[:id])
    haml :view
  rescue ActiveRecord::RecordNotFound
    redirect '/'
  end  
end

# edit form
get '/edit/:id' do
  begin
    @post = Post.find(params[:id])
    @back = request.referer || '/';
    haml :edit, :layout => false
  rescue ActiveRecord::RecordNotFound
    redirect '/'
  end
end

# edit existing post
post '/edit/:id' do
  if Post.update(params[:id], :content => params[:content].gsub(/\n/, ' '), :emo => params[:emo])
    redirect "/#{params[:id]}"
  else
    # reset to GET
    # http://www.gittr.com/index.php/archive/details-of-sinatras-redirect-helper/
    redirect "/edit/#{params[:id]}", 303
  end
end

# delete post
delete '/delete' do
  content_type :json
  
  if Post.delete(params[:id])
    {:result => 'success'}.to_json
  else
    {:result => 'failed'}.to_json
  end
end

# browse by emo
# most recent 7 posts only
get '/:emo/days' do
  @posts = Post.find(:all, :limit => 7, :conditions => "emo = '#{params[:emo]}'", :order => 'created_at DESC')
  @listing = "Your most recent 7 <em>#{params[:emo].gsub(/_/, "'")}</em> days"
  
  haml :listing
end

# browse by week
get '/:no/weeks?/ago' do
  start_timestamp = Time.now - params[:no].to_i * 60 * 60 * 24 * 7
  end_timestamp = start_timestamp + 60 * 60 * 24 * 7
  @posts = Post.find(:all, :conditions => {:created_at => start_timestamp..end_timestamp}, :order => 'created_at DESC').reverse
  @listing = "What you did #{params[:no].to_i > 1 ? "#{params[:no]} weeks ago" : 'last week'}"
  
  haml :listing
end

# random listing
get '/random' do
  @posts = Post.find(:all, :order => 'RANDOM()', :limit => 3)

  haml :random
end

# random entries via json
post '/random' do
  content_type :json
  
  posts = Post.find(:all, :order => 'RANDOM()', :limit => 7)
  
  posts.to_json
end

# when did you make your last post?
def days_ago timestamp, verbose = false
  seconds = (Time.now - timestamp).abs
  days = (seconds / 60 / 60 / 24).round
  verbose ? "#{days} day#{days > 1 ? 's' : ''}" : days
end

helpers do
  # basic auth
  def protected!
    response['WWW-Authenticate'] = %(Basic realm="Identify yourself") and \
    throw(:halt, [401, "Access Denied\n"]) and \
    return unless authorized?
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials[0] == ACCOUNT['username'] && Digest::MD5.hexdigest(SECRET + @auth.credentials[1]) == ACCOUNT['password']
  end

  # any questions?
  def nice_time timestamp, exact = false
    exact ? timestamp.strftime('%A, %B %d %Y at %I:%M%p') : timestamp.strftime('%A, %B %d %Y')
  end
  
  # escape html
  include Rack::Utils
  alias_method :h, :escape_html
end

# for production use
configure :production do
  not_found do
    'This is nowhere to be found'
  end
  
  error do
    'Sorry there was a nasty error - ' + request.env['sinatra.error'].name
  end
end

# for development purpose only
# please keep out
get '/defcon/1' do
  status 404 unless development?
  
  Post.delete_all
  
  "It's Global Thermonuclear War, and nobody wins. But maybe - just maybe - you can lose the least. (http://www.introversion.co.uk/defcon/)"
end

get '/viral/outbreak' do
  status 404 unless development?
  
  posts = []
  buckets = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.".split('. ')
  timemachine = Time.now
  
  1.upto 50 do |i|
    posts << {
      :content => buckets[rand(buckets.length)],
      :emo => EMO[rand(EMO.length)],
      :created_at => timemachine,
      :updated_at => timemachine
    }
    timemachine -= (60 * 60 * 24 * rand()).round
  end
  Post.create posts
  
  "It's fast, it's furious and only the flattest will survive! (http://www.introversion.co.uk/multiwinia/)"
end