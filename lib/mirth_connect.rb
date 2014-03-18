require "mirth_connect/version"
require "mirth_connect/helpers"
require "mirth_connect/connection"
require 'rest-client'
require 'nori'

module MirthConnect

  # Convience for MirthConnect::Connection.new
  def self::connect( server, port, username, password, version )
    unless active? && @connection.same_connection?( server, port, username, password, version )
      @connection = MirthConnect::Connection.new( server, port, username, password, version )
    end
    @connection
  end

  def self::active?
    begin
      @connection.active?
    rescue
      false
    end
  end

  def self::connection
    @connection
  end

end
