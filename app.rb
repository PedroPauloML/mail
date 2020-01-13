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

SITE_NAME = "Mail"