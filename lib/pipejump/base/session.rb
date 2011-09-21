module Pipejump

  # The Pipejump::Session instance represents an active Session with the Pipejump API
  #
  # Any access to the Pipejump API requires authentication, which means you need to initialize a
  # Pipejump::Session instance before calling any other methods
  #
  # == Authentication
  #
  # To authenticate, simply call Pipejump::Session.new with a argument hash with the following keys:
  #
  # * _email_ - your Pipejump user account email
  # * _password_ - your Pipejump user account password
  # * _endpoint_ - (optional) Default is https://sales.futuresimple.com, however you can override it (for example for development)
  #
  # You can perform later actions either on a instance returned by the canstructor or within a supplied block
  #
  #
  #     @session = Pipejump::Session.new(:email => EMAIL, :password => PASSWORD)
  #     @session.account
  #
  #
  # or
  #
  #
  #     Pipejump::Session.new(:email => EMAIL, :password => PASSWORD) do |session|
  #       session.account
  #     end
  #
  # As of version 0.1.1 you can use the token which is fetched when authenticating using the email and password. So once you get the token, you can use it for future initialization of the Session and not send the username and password, which is a more secure.
  #
  #   @session = Pipejump::Session.new(:token => 'your_token')
  #
  # Also, as of version 0.1.1 connection is performed over SSL.
  #
  #
  #
  #
  # == Account
  #
  # To access the Account instance, call the account method
  #
  #
  #      @session.account # => #<Pipejump::Account name: "myaccount", id: "1", currency_name: "$">
  #
  #
  # == Deals
  #
  # You can access your deals by calling
  #
  #
  #      @session.deals
  #
  #
  # With Deals you get access to Notes, Reminders and Deal Contacts.
  #
  # For more information, consult the Deals page.
  #
  # == Clients
  #
  # You can access your clients by calling
  #
  #
  #      @session.clients
  #
  #
  # For more information, consult the Clients page.
  #
  # == Contacts
  #
  # You can access your contacts by calling
  #
  #
  #      @session.contacts
  #
  #
  # For more information, consult the Contacts page.
  #
  # == Sources
  #
  # You can access your sources by calling
  #
  #
  #      @session.sources
  #
  #
  # For more information, consult the Sources page.
  #
  class Session

    attr_accessor :token, :version

    def initialize(params, &block)
      if endpoint = params.delete("endpoint") or endpoint = params.delete(:endpoint)
        connection(endpoint)
      end

      if version = params.delete('version') or version = params.delete(:version)
        self.version = "v#{version}"
      else
        self.version = "v1"
      end
      # If user supplies token, do not connect for authentication
      if token = params.delete('token') or token = params.delete(:token)
        self.token = token
      else
        authenticate(params)
      end
      yield(self) if block_given?
    end

    def version_prefix(url)
      if self.version and !url.match(/^\/api\/#{self.version}/)
        "/api/#{self.version}#{url}"
      else
        url
      end
    end

    def authenticate(params) #:nodoc:
      response = connection.post(version_prefix('/authentication.json'), params.collect { |pair| pair.join('=') }.join('&'))
      data = JSON.parse(response.body)
      self.token = data['authentication']['token']
      raise AuthenticationFailed if response.code == '401'
    end

    def connection(endpoint = nil) #:nodoc:
      @connection ||= Connection.new(self, endpoint)
    end

    def get(url) #:nodoc:
      response = connection.get(url)
      data = (response.code.to_i == 200 and url.match('.json')) ? JSON.parse(response.body) : ''
      [response.code.to_i, data]
    end

    def post(url, data) #:nodoc:
      response = connection.post(url, data)
      data = url.match('.json') ? JSON.parse(response.body) : response.body
      [response.code.to_i, data]
    end

    def put(url, data) #:nodoc:
      response = connection.put(url, data)
      data = url.match('.json') ? JSON.parse(response.body) : response.body
      [response.code.to_i, data]
    end

    def delete(url) #:nodoc:
      response = connection.delete(url)
      [response.code.to_i, response.body]
    end

    def inspect
      "#<#{self.class} token: \"#{token}\">"
    end

    # Returns a Pipejump::Account instance of the current account
    def account
      code, response = get(version_prefix('/account.json'))
      Account.new(response['account'])
    end

    # Returns a Pipejump::Collection instance of Clients
    def clients
      @clients = Collection.new(self, Client)
    end

    # Returns a Pipejump::Collection instance of Sources
    def sources
      @sources = Collection.new(self, Source)
    end

    # Returns a Pipejump::Collection instance of Contacts
    def contacts
      @contacts = Collection.new(self, Contact)
    end

    # Returns a Pipejump::Collection instance of Deals
    def deals
      @deals = Collection.new(self, Deal)
    end


  end
end