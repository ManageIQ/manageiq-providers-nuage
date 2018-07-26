class ManageIQ::Providers::Nuage::NetworkManager::VsdClient::Rest
  include Vmdb::Logging
  def initialize(server, user, password)
    @server = server
    @user = user
    @password = password
    @api_key = ''
    reset_headers
  end

  def login
    @login_url = @server + "/me"
    RestClient::Request.execute(:method => :get, :url => @login_url, :user => @user, :password => @password,
    :headers => @headers, :verify_ssl => false) do |response|
      case response.code
      when 200
        data = JSON.parse(response.body)
        extracted_data = data[0]
        @api_key = extracted_data["APIKey"]
        return true, extracted_data["enterpriseID"]
      else
        raise MiqException::MiqInvalidCredentialsError, "Login failed due to a bad username, password or unsupported API version."
      end
    end
  end

  class << self
    attr_reader :server
  end

  def append_headers(key, value)
    @headers[key] = value
  end

  def reset_headers
    @headers = {
      'X-Nuage-Organization' => 'csp',
      'Content-Type'         => 'application/json; charset=UTF-8'
    }
  end

  def get(url)
    request(url)
  end

  def delete(url)
    request(url, :method => :delete)
  end

  def put(url, data)
    request(url, :method => :put, :data => data)
  end

  def post(url, data)
    request(url, :method => :post, :data => data)
  end

  def request(url, method: :get, data: nil, verify_ssl: false)
    $nuage_log.debug("Accessing Nuage VSD url #{method} #{url} with data '#{data}'")
    login unless @api_key
    RestClient::Request.execute(
      :url        => url,
      :method     => method,
      :headers    => @headers,
      :data       => data,
      :user       => @user,
      :password   => @api_key,
      :verify_ssl => verify_ssl
    ) { |response| response } # silence errors like 404
  end
end
