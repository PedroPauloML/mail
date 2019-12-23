require 'sinatra'
require 'json'
require_relative "libs/mail_intercepter"

get "/" do
  @page_title = "List of mails"
  erb :index
end

get "/inbox.json" do
  content_type :json
  mi = MailIntercepter.new
  { inbox: mi.inbox }.to_json
end

SITE_NAME = "Mail"