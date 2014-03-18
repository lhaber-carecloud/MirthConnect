require 'mirth_connect'
require 'mirth_connect/helpers'

class MirthConnect::Connection

  attr_accessor :url, :cookie, :password, :username, :version
  attr_accessor :current_filter

  HELPERS = MirthConnect::Helpers

  def initialize( server, port, username, password, version)
    @url = "https://#{server}:#{port}/"
    @password = password
    @username = username
    @version  = version
    begin
      @cookie = login(password, username, version).cookies
    rescue => e
      throw Exception, e
    end
  end

  def eql?( other_conn )

    ( @url == other_conn.url &&
      @username == other_conn.username &&
      @password == other_conn.password &&
      @version == other_conn.version      )

  end

  def same_connection?( server, port, username, password, version )

    ( @url == "https://#{server}:#{port}/" &&
      @username == username &&
      @password == password &&
      @version == version )

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
    mirth_request( 'users', 'login', {:username => username, :password => password, :version => version} )
  end

  def channel_status_list
   parse_channel_status_list( mirth_request( 'channelstatus', 'getChannelStatusList' ) )
  end

  def channel_id_name_hash
    id_list = Hash.new
    channel_status_list.each{|c| id_list[ c[:channelId] ] = c[:name] }
    id_list
  end

  def get_message_by_id( message_id )
    create_message_filter( :filter => {:id => message_id} )
    get_message
  end

  def get_messages_between( start_date, end_date, filter = {} )
    count_messages_between( start_date, end_date, filter)
    get_messages
  end

  def get_messages_by_channel( channel_id, filter = {} )
    count_messages_by_channel( channel_id, filter )
    get_messages
  end

  def get_messages_today( channel_id, filter = {} )
    count_messages_today( channel_id, filter )
    get_messages
  end

  def count_messages_today( channel_id, filter = {} )
    filter[:channelId] = channel_id
    count_messages_between( Date.today.to_time, Time.now, filter)
  end

  def count_messages_by_channel( channel_id, filter = {} )
    channel_filter = {:channelId => channel_id}
    channel_filter = filter.merge( channel_filter )
    create_message_filter( :filter => channel_filter )
  end

  def count_messages_between( start_date, end_date, filter = {} )
    time_filter = {:startDate => {:time => Helpers.unix_13_digit_time(start_date), :timezone =>'America/New York'},
                   :endDate   => {:time => Helpers.unix_13_digit_time(end_date),   :timezone =>'America/New York'} }
    time_filter = filter.merge( time_filter )
    create_message_filter( :filter => time_filter )
  end



  protected

  def get_message( should_parse = true )
    begin
      message = mirth_request('messages', 'getMessagesByPage', {:maxMessages => 1})
    rescue
      return nil
    end

    return nil if message == '<list/>'

    if should_parse
      message = Nokogiri::XML(message).search('messageObject')
      parse_message(message)
    else
      message
    end

  end

  def get_messages( should_parse = true )
    begin
      message_list = mirth_request('messages', 'getMessagesByPage')
    rescue
      return []
    end

    return [] if message_list == '<list/>'

    if should_parse
      parse_message_list(message_list)
    else
      message
    end
  end

  def create_message_filter( filter = {} )
    @current_filter = Helpers.validate_message_filter( filter )
    mirth_request('messages', 'removeFilterTables')
    Integer mirth_request('messages', 'createMessagesTempTable', @current_filter )
  end

  def parse_message( message )

    parsed_message = Hash.new

    message_params = Helpers.message_object_params
    message_params.each do |n|

      parsed_message[n] = if n == :dateCreated
                            o = Hash.new
                            begin
                              o[:time] = message.at(n).at(:time).text
                              o[:timezone] = message.at(n).at(:timezone).text
                            rescue
                              o = nil
                            end
                            o
                          elsif n.to_s.include?('Map')
                            entries = Array.new
                            begin
                              message.at(n).search('entry').map do |entry|
                                strings = Array.new
                                entry.search('string').map do |string|
                                  strings << string.text
                                end
                                entries << {:string => strings}
                              end
                            rescue
                              # ignored
                            end
                            {:entry => entries}
                          else
                            begin
                              message.at(n).text
                            rescue
                              nil
                            end
                          end

    end

    parsed_message

  end

  def parse_channel_status ( channel )

    parsed_channel = Hash.new

    channel_status_params = Helpers.channel_status_params
    channel_status_params.each do |n|
      parsed_channel[n] = if n == :deployedDate
                            o = Hash.new
                            begin
                              o[:time] = channel.at(n).at(:time).text
                              o[:timezone] = channel.at(n).at(:timezone).text
                            rescue
                              o = nil
                            end
                            o
                          else
                            begin
                              channel.at(n).text
                            rescue
                              nil
                            end
                          end

    end

    parsed_channel

  end

  def parse_message_list( list )

    xml = Nokogiri::XML(list)
    messages = Array.new
    xml.search('messageObject').map do |message|
      messages << parse_message(message)
    end
    messages

  end

  def parse_channel_status_list( list )

    xml = Nokogiri::XML(list)
    status = Array.new
    xml.search('channelStatus').map do |channel|
      status << parse_channel_status(channel)
    end
    status

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
      payload[:page]        = opts[:page]        || 0
      payload[:pageSize]    = opts[:pageSize]    || 999999
      payload[:maxMessages] = opts[:maxMessages] || 999999
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

    response

  end
end

