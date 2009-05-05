require 'rubygems'
require 'sinatra'
require 'active_record'

# config
unless defined? DEBUG
  DEBUG = true
  HTML_ESCAPE = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#039;'}
  EMO = %w{cry misdoubt rockn_roll smile unhappy wicked}
  DEFAULT_EMO = 'misdoubt'
end

mime :json, "application/json"

# create db if needed
configure do 
  dbconfig = YAML.load(File.read('config/database.yml'))
  ActiveRecord::Base.establish_connection dbconfig['development']
  
  begin
    ActiveRecord::Schema.define do
      create_table :posts do |t|
        t.string :content, :null => false, :limit => 140
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
  validates_length_of :content, :in => 1..140
  validates_inclusion_of :emo, :in => EMO
  validate :valid_time?
  
  private
  
  def valid_time?
    @last_post = Post.find(:first, :order => 'created_at DESC')
    if @last_post && days_ago(@last_post.created_at) < 1 && !DEBUG
      # this has nothing to do w/ content
      errors.add :content
    end
  end
end

# entry point
# redirect to post listing if post of the day has been made
# otherwise, show new post form
['/', '/new'].each do |path|
  get path do
    @last_post = Post.find(:first, :order => 'created_at DESC')
    p DEBUG
    if !@last_post || days_ago(@last_post.created_at) >= 1 || DEBUG
      haml :new, :layout => false
    else
      haml :already, :layout => false
    end
  end
end

# create a new post
post '/new' do
  @post = Post.new(:content => params[:content].gsub(/\n/, ' '), :emo => params[:emo])
  if @post.save
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
  if Post.update(params[:id], :content => params[:content], :emo => params[:emo])
    redirect "/#{params[:id]}"
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
  start_timestamp = Time.now - params[:no].to_i * 60 * 60 * 24 * 7;
  end_timestamp = start_timestamp + 60 * 60 * 24 * 7;
  @posts = Post.find(:all, :limit => 7, :conditions => ['created_at BETWEEN ? AND ?', start_timestamp, end_timestamp], :order => 'created_at DESC').reverse
  @listing = "What you did #{params[:no].to_i > 1 ? "#{params[:no]} weeks ago" : 'last week'}"
  haml :listing
end


# both helper and processing helper
def days_ago timestamp, verbose = false
  seconds = (Time.now - timestamp).abs
  days = (seconds / 60 / 60 / 24).round
  verbose ? "#{days} day#{days > 1 ? 's' : ''}" : days
end

helpers do
  # any questions?
  def nice_time timestamp, exact = false
    exact ? timestamp.strftime('%A, %B %d %Y at %I:%M%p') : timestamp.strftime('%A, %B %d %Y')
  end
  
  # escape html
  def h text    
    text.to_s.gsub(/[\"><&]/) { |s| HTML_ESCAPE[s] }
    text
  end
end