require 'mirth_connect/helpers'
require 'mirth_connect/channel_status'
require 'mirth_connect/message'
require 'mirth_connect/filter'

class MirthConnect::Connection

  attr_accessor :url, :version
  attr_accessor :current_filter

  HELPERS = MirthConnect::Helpers

  def initialize( server, port, username, password, version, protocol )
    @url = "#{protocol}://#{server}:#{port}/"
    @version  = version
    begin
      @cookie = login(password, username, version).cookies
    rescue
      raise Exception, 'check login credentials'
    end
  end

  def active?
    channel_status_list
    return true
    rescue
      return false
  end

  def login(password, username, version)
    mirth_request( 'users', 'login', {:username => username, :password => password, :version => version} )
  end

  def channel_status_list
    list = Array.new
    xml = Nokogiri::XML(mirth_request( 'channelstatus', 'getChannelStatusList' ))
    xml.search('channelStatus').each{ |channel| list << MirthConnect::ChannelStatus.new(channel) }
    list
  end

  def channel_id_name_hash
    id_list = Hash.new
    channel_status_list.each{|c| id_list[ c[:channelId] ] = c[:name] }
    id_list
  end

  def count_messages( filter_opts )
    create_message_filter( MirthConnect::Filter.new( filter_opts ) )
  end

  def count_messages_today( filter_opts = {} )
    create_message_filter( MirthConnect::Filter.today( filter_opts ) )
  end

  def get_message( filter_opts )
    num = count_messages( filter_opts )
    raise Exception, 'more than one message for given filter'  if num > 1
    retrieve_message
  end

  def get_messages( filter_opts )
    count_messages( filter_opts )
    retrieve_messages
  end

  def get_messages_today( filter = {} )
    count_messages_today( filter )
    retrieve_messages
  end



  protected

  def retrieve_message
    xml = Nokogiri::XML(mirth_request( 'messages', 'getMessagesByPage' ))
    MirthConnect::Message.new( xml.search('messageObject')[0] )
  end

  def retrieve_messages
    list = Array.new
    xml = Nokogiri::XML(mirth_request( 'messages', 'getMessagesByPage' ))
    xml.search('messageObject').each{|message| list << MirthConnect::Message.new(message) }
    list
  end


  def create_message_filter( filter )
    @current_filter = filter if filter.is_a?(MirthConnect::Filter)
    mirth_request('messages', 'removeFilterTables')
    Integer mirth_request('messages', 'createMessagesTempTable', {:filter => @current_filter} )
  end

  def mirth_request (endpoint, method, opts = {})

    url = @url + "#{endpoint}?op=#{method}"

    payload = Hash.new

    if method == 'login'
      payload[:username] = opts[:username] if opts[:username]
      payload[:password] = opts[:password] if opts[:password]
      payload[:version]  = opts[:version]  if opts[:version]
    end
    if method == 'createMessagesTempTable' || method == 'getMessagesByPageLimit'
      payload[:filter]  = opts[:filter].to_xml_string if opts[:filter] && opts[:filter].is_a?(MirthConnect::Filter)
    end
    if method == 'getMessagesByPage' || method == 'getMessagesByPageLimit'
      payload[:page]        = opts[:page]        || 0
      payload[:pageSize]    = opts[:pageSize]    || 999999
      payload[:maxMessages] = opts[:maxMessages] || 999999
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

