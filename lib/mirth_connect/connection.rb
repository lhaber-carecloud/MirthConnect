require 'mirth_connect'
require 'mirth_connect/helpers'

class MirthConnect::Connection

  attr_accessor :url, :cookie, :password, :username, :version
  attr_accessor :current_filter

  Helpers = MirthConnect::Helpers

  def initialize( server, port, username, password, version)
    @url = "https://#{server}:#{port}/"
    @password = password
    @username = username
    @version  = version
    @cookie = login(password, username, version).cookies
  end

  def active?
    begin
      channel_status_list
    rescue
      false
    end
    true
  end

  def login(password, username, version)
    mirth_request( 'users', 'login', false, {:username => username, :password => password, :version => version} )
  end

  def channel_status_list
    mirth_request( 'channelstatus', 'getChannelStatusList', true )['list']['channelStatus']
  end

  def channel_id_list
    channel_status_list.map{|c| c['channelId']}
  end

  def get_message_by_id( message_id )
    create_message_filter( :filter => {:id => message_id} )
    mirth_request('messages', 'getMessagesByPage', true)['list']['messageObject']
  end

  def get_messages_between( start_date, end_date, filter = {} )
    count_messages_between( start_date, end_date, filter)
    mirth_request('messages', 'getMessagesByPage', true)['list']['messageObject']
  end

  def get_messages_by_channel( channel_id, filter = {} )
    count_messages_by_channel( channel_id, filter )
    mirth_request('messages', 'getMessagesByPage', true)['list']['messageObject']
  end

  def count_messages_by_channel( channel_id, filter = {} )
    channel_filter = {:channelId => channel_id}
    channel_filter = Helpers.validate_message_filter(filter).merge( channel_filter )

    create_message_filter( :filter => channel_filter)
  end

  def count_messages_between( start_date, end_date, filter = {} )
    time_filter = {:startDate => {:time => Helpers.unix_13_digit_time(start_date), :timezone =>'America/New York'},
                   :endDate   => {:time => Helpers.unix_13_digit_time(end_date),   :timezone =>'America/New York'} }

    filter = Helpers.validate_message_filter(filter).merge( time_filter )

    create_message_filter( :filter => filter )
  end

  def create_message_filter( opts = {} )
    @current_filter =  opts
    mirth_request('messages', 'removeFilterTables', false)
    num_messages = Integer mirth_request('messages', 'createMessagesTempTable', false, @current_filter )
    num_messages
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

  def mirth_request (endpoint, method, should_parse_output, opts = {})

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

    should_parse_output ? Nori.new.parse(response) : response

  end
end

