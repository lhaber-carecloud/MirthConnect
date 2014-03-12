class MirthConnect::Connection

  attr_accessor :url, :cookie, :password, :username, :version
  attr_accessor :current_filter

  def initialize( server, port, username, password, version)
    @url = "https://#{server}:#{port}/"
    @cookie = login(password, username, version).cookies
  end

  def login(password, username, version)
    @password = password
    @username = username
    @version  = version
    mirth_request( 'users', 'login', {:username => username, :password => password, :version => version} )
  end

  def channel_status_list
    mirth_request( 'channelstatus', 'getChannelStatusList' )['list']['channelStatus']
  end

  def get_message_by_id( message_id )
    create_message_filter( :filter => {:id => message_id} )
    mirth_request('messages', 'getMessagesByPage')['list']['messageObject']
  end

  def create_message_filter( opts = {} )
    @current_filter =  opts
    mirth_request('messages', 'removeFilterTables')
    mirth_request('messages', 'createMessagesTempTable', @current_filter )
  end

  def to_mirth_xml ( hash )

    return hash unless hash.is_a?(Hash)

    xml = ''
    hash.each_pair do |key, value|
      xml << "<#{key}>"
      case
        when value.is_a?(Hash)
          xml << to_mirth_xml(value)
        when value.is_a?(Array)
          value.each_with_index do |el, i|
            xml << "<#{key}>"       unless i == 0
            xml << to_mirth_xml(el) unless el.nil?
            xml << "</#{key}>"      unless i == (value.length - 1)
          end
        when value.is_a?(String)
          xml << value.encode(:xml => :attr).delete('"')
        else
          xml << "#{value}"
      end
      xml << "</#{key}>"
    end
    xml
  end

  def mirth_request (endpoint, method, opts = {})

    url = @url + "#{endpoint}?op=#{method}"

    payload = Hash.new

    if method == 'login'
      payload[:username] = opts[:username] if opts[:username]
      payload[:password] = opts[:password] if opts[:password]
      payload[:version]  = opts[:version] if opts[:version]
    end
    if method == 'createMessagesTempTable' || method == 'getMessagesByPageLimit'
      payload[:filter]  = to_mirth_xml( {:messageObjectFilter => opts[:filter]}) unless opts[:filter].nil?
    end
    if method == 'getMessagesByPage' || method == 'getMessagesByPageLimit'
      payload[:page]        = 0
      payload[:pageSize]    = 999999
      payload[:maxMessages] = 999999
    end
    if method == 'processMessage' || method == 'reprocessMessage'
      payload[:message] = to_mirth_xml( {:messageObject => opts[:message]}) unless opts[:message].nil?
      payload[:destinations] = to_mirth_xml( {:list => opts[:destinations]}) unless opts[:destinations].nil?
      payload[:cachedChannels] = to_mirth_xml( {:map => opts[:cachedChannels]}) unless opts[:cachedChannels].nil?
    end

    payload[:uid] = 0 if endpoint == 'messages'


    begin
      response = RestClient.post  url, payload, :cookies => @cookie
    rescue => e

      case e.to_s
        when '403 Forbidden'

          puts 'LOGGING INTO MIRTH...'
          @cookie = login(@password, @username, @version).cookies

          begin
            response = RestClient.post  url, payload, :cookies => @cookie
          rescue
            raise e, 'Cannot Log Into Mirth'
          end

        when '500 Internal Server Error'

          puts e
          puts 'CHECK PAYLOAD ARGUMENTS:'
          payload.each_pair {|k,v| puts "#{k}: #{v}\n"}

          return

        else

          puts e

          return
      end

    end

    if method == 'login'
      response
    else
      Nori.new().parse(response)
    end

  end
end