module MailIntercepter
  class GMAIL
    # For more details about methods of gem "google-api-ruby-client", check this
    # URL: https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google/apis/gmail_v1/service.rb
    require "google/apis/gmail_v1"
    require "googleauth"
    require "googleauth/stores/file_token_store"
    require "fileutils"

    OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
    APPLICATION_NAME = "Gmail API Ruby Quickstart".freeze
    CREDENTIALS_PATH = "#{__dir__}/gmail/credentials.json".freeze
    # The file token.yaml stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    TOKEN_PATH = "#{__dir__}/gmail/token.yaml".freeze
    SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

    attr_reader :service

    def initialize
      @service = Google::Apis::GmailV1::GmailService.new
      @service.client_options.application_name = APPLICATION_NAME
      @service.authorization = authorize
    end

    def labels
      user_id = "me"
      result = @service.list_user_labels user_id
      puts "Labels:"
      puts "No labels found" if result.labels.empty?
      result.labels.each { |label| puts "- #{label.name}" }
    end

    def inbox(options = {})
      puts ">>> options: #{options}"
      options = JSON.parse(options.to_json, symbolize_names: true)

      response = @service.list_user_messages("me", **options)
      data = response.messages || []

      if data.count > 0
        data = data[0..10].collect do |message|
          get_message("me", message.id)
        end
      end
      next_page_token = response.next_page_token

      return  {
        data: data,
        next_page_token: next_page_token
      }
    end

    def get_message(from, id)
      result = @service.get_user_message(from, id)
      payload = result.payload
      headers = payload.headers
      object = {}

      object[:id] = id

      if headers.any? { |h| h.name == 'Date' }
        object[:date] = headers.find { |h| h.name == 'Date' }.value
        object[:date_formatted] = (
          begin
            DateTime.strptime(object[:date], "%a, %d %b %Y %T %z")
              .new_offset(-3.0/24)
              .strftime("%d/%m/%Y %T")
          rescue Exception => ex
            "#{ex} (#{object[:date].inspect})"
          end
        )
      else
        object[:date] = ""
      end

      if headers.any? { |h| h.name == 'From' }
        object[:from] = headers.find { |h| h.name == 'From' }.value
      else
        object[:from] = ""
      end

      if headers.any? { |h| h.name == 'To' }
        object[:to] = headers.find { |h| h.name == 'To' }.value
      else
        object[:to] = ""
      end

      if headers.any? { |h| h.name == 'Subject' }
        object[:subject] = headers.find { |h| h.name == 'Subject' }.value
      else
        object[:subject] = ""
      end

      if result.label_ids.include?("UNREAD")
        object[:unread] = true
      else
        object[:unread] = false
      end

      object[:body] = payload.body.data
      if object[:body].nil? && payload.parts.any?
        object[:body] = payload.parts.map { |part| part.body.data }.join
      end

      object
    end

    def thread(id, options = {})
      @service.get_user_thread("me", id, options).messages.collect do |message|
        get_message("me", message.id)
      end
    end

    private

    ##
    # Ensure valid credentials, either by restoring from the saved credentials
    # files or intitiating an OAuth2 authorization. If authorization is required,
    # the user's default browser will be launched to approve the request.
    #
    # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
    def authorize
      client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
      token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
      authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
      user_id = "default"
      credentials = authorizer.get_credentials user_id
      if credentials.nil?
        url = authorizer.get_authorization_url base_url: OOB_URI
        puts "Open the following URL in the browser and enter the " \
            "resulting code after authorization:\n" + url
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: OOB_URI
        )
      end
      credentials
    end
  end

  class OUTLOOK
    # For more details, read this tutorial https://docs.microsoft.com/pt-br/outlook/rest/ruby-tutorial

    require "oauth2"
    require "microsoft_graph"
    require "nokogiri"

    attr_reader :graph

    # Scopes required by the app
    SCOPES = [ 'openid', 'profile', 'offline_access', 'User.Read', 'Mail.Read' ]

    REDIRECT_URI = 'http://localhost:3000/authorize'

    def initialize(session)
      tokens = JSON.parse(File.open("#{__dir__}/outlook/token.json").readlines.join(""))
      @client_id = tokens["client-id"]
      @client_secret = tokens["client-secret"]
      get_access_token(session)
    end

    # Generates the login URL for the app.
    def get_login_url
      client = OAuth2::Client.new(
        @client_id,
        @client_secret,
        :site => 'https://login.microsoftonline.com',
        :authorize_url => '/common/oauth2/v2.0/authorize',
        :token_url => '/common/oauth2/v2.0/token'
      )

      login_url = client.auth_code.authorize_url(
        :redirect_uri => REDIRECT_URI, :scope => SCOPES.join(' ')
      )
    end

    # Exchanges an authorization code for a token
    def get_token_from_code(auth_code)
      client = OAuth2::Client.new(
        @client_id,
        @client_secret,
        :site => 'https://login.microsoftonline.com',
        :authorize_url => '/common/oauth2/v2.0/authorize',
        :token_url => '/common/oauth2/v2.0/token'
      )

      token = client.auth_code.get_token(
        auth_code, :redirect_uri => REDIRECT_URI, :scope => SCOPES.join(' ')
      )
    end

    def inbox
      callback = Proc.new do |r|
        r.headers['Authorization'] = "Bearer #{@access_token}"
      end

      @graph = MicrosoftGraph.new(
        base_url: 'https://graph.microsoft.com/v1.0',
        cached_metadata_file: File.join(MicrosoftGraph::CACHED_METADATA_DIRECTORY, 'metadata_v1.0.xml'),
        &callback
      )

      messages = @graph.me.mail_folders.find('inbox').messages.order_by('receivedDateTime desc')

      {
        data: (
          messages.first(10).collect do |message|
            {
              id: message.id,
              date: message.received_date_time.to_s,
              date_formatted: message.received_date_time.strftime("%d/%m/%Y %T"),
              from: "#{message.from.email_address.name} <#{message.from.email_address.address}>",
              # to: "#{message.from.email_address.name} <#{message.from.email_address.address}>",
              subject: message.subject,
              body: message.body.content,
            }
          end
        )
      }
    end

    private

    # Gets the current access token
    # def get_access_token
    def get_access_token(session)
      # Get the current token hash from session
      token_hash = session[:azure_token]

      if token_hash
        client = OAuth2::Client.new(
          @client_id,
          @client_secret,
          :site => 'https://login.microsoftonline.com',
          :authorize_url => '/common/oauth2/v2.0/authorize',
          :token_url => '/common/oauth2/v2.0/token'
        )

        token = OAuth2::AccessToken.from_hash(client, token_hash)

        # Check if token is expired, refresh if so
        if token.expired?
          new_token = token.refresh!
          # Save new token
          session[:azure_token] = new_token.to_hash
          @access_token = new_token.token
        else
          @access_token = token.token
        end
      else
        @access_token = nil
      end
    end
  end
end