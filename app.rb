# encoding: utf-8
require 'sinatra'
require 'json'
require_relative "libs/mail_intercepter"

Encoding.default_external = "UTF-8"
set default_encoding: "UTF-8"

get "/" do
  @page_title = "List of mails"
  erb :index
end

get "/inbox.json" do
  content_type :json
  mi = MailIntercepter.new
  puts ">>> page: #{params[:page]}"
  messages = mi.inbox(params[:page] || 1)
  messages.each_with_index do |v, i|
    messages[i][:body] = v[:body].force_encoding("ISO-8859-1").encode("UTF-8")
  end
  { inbox: messages }.to_json
end

SITE_NAME = "Mail"