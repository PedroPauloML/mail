# encoding: utf-8
require 'sinatra'
require 'json'
require 'sinatra/base'
require_relative "libs/mail_intercepter"

Encoding.default_external = "UTF-8"
set default_encoding: "UTF-8"
use Rack::Session::Pool

get "/" do
  @page_title = "List of mails"
  @session = session
  @outlook_login_url = MailIntercepter::OUTLOOK.new(session).get_login_url
  erb :index
end

get "/gmail_inbox.json" do
  content_type :json
  # raise ">>> params: #{params}"
  mi = MailIntercepter::GMAIL.new
  response = mi.inbox(params[:options] || {})
  response[:data].each_with_index do |v, i|
    response[:data][i][:body] = v[:body].force_encoding("ISO-8859-1").encode("UTF-8")
  end
  response.to_json
end

get "/outlook_inbox.json" do
  content_type :json
  # raise ">>> params: #{params}"
  mi = MailIntercepter::OUTLOOK.new(session)
  response = mi.inbox
  response[:data].each_with_index do |v, i|
    response[:data][i][:body] = v[:body].force_encoding("ISO-8859-1").encode("UTF-8")
  end
  response.to_json
end

get "/authorize" do
  begin
    token = MailIntercepter::OUTLOOK.new(session).get_token_from_code(params[:code])
  rescue Exception => ex
    return ex.to_s
  end

  session[:azure_token] = token.to_hash
  puts ">>> session[:azure_token]: #{session[:azure_token]}"
  redirect "/"
end

SITE_NAME = "Mail"