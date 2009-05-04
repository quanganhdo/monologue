require 'rubygems'
require 'sinatra'
require 'active_record'

configure do 
  dbconfig = YAML.load(File.read('config/database.yml'))
  ActiveRecord::Base.establish_connection dbconfig['development']
  
  begin
    ActiveRecord::Schema.define do
      create_table :posts do |t|
        t.string :content, :null => false, :limit => 140
        t.timestamps
      end
    end
  rescue ActiveRecord::StatementInvalid
      # do nothing
  end
end

class Post < ActiveRecord::Base
  validates_presence_of :content
end

get '/' do
  @last_post = Post.find(:first, :order => 'created_at DESC')
  if days_ago(@last_post.created_at) >= 1
    haml :index, :layout => false
  else
    redirect '/all'
  end
end

get '/all' do
  @posts = Post.find(:all, :order => 'created_at DESC')
  haml :all
end

get '/:id' do
  @post = Post.find(params[:id])
  haml :view
end

post '/new' do
  @post = Post.new(:content => params[:content])
  if @post.save
    redirect '/all'
  else
    redirect '/'
  end
end

def days_ago timestamp
  seconds = (Time.now - timestamp).abs
  seconds / 60 / 60 / 24
end