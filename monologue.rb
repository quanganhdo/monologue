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
  # nothing to see here
end

get '/' do
  @posts = Post.find(:all)
  haml :index
end

get '/:id' do
  @post = Post.find(params[:id])
  haml :view
end

post '/new' do
  @post = Post.new(:content => params[:content])
  if @post.save
    redirect '/'
  end
end