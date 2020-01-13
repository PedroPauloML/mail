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
end