require 'rubygems'
require 'sinatra'
require 'active_record'

configure do 
  dbconfig = YAML.load(File.read('config/database.yml'))
  ActiveRecord::Base.establish_connection dbconfig['development']
  
  begin
    ActiveRecord::Schema.define do
      create_table :entries do |t|
        t.string :content, :null => false, :limit => 140
        t.timestamps
      end
    end
  rescue ActiveRecord::StatementInvalid
      # do nothing
  end
end

class Entry < ActiveRecord::Base
  # nothing to see here
end

get '/' do
  haml :index
end