require "mirth_connect/version"
require "mirth_connect/connection"
require 'rest-client'
require 'nori'

module MirthConnect


  # Convience for MirthConnect::Connection.new
  def self::connect( server, port, username, password, version )
    @connection = MirthConnect::Connection.new( server, port, username, password, version )
    @connection
  end

  def self::active?
    !@connection.nil?
  end

  def self::connection
    @connection
  end

end
