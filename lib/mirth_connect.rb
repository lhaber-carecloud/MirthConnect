require "mirth_connect/version"
require "mirth_connect/connection"
require 'rest-client'
require 'nori'

module MirthConnect

  # Convience for MirthConnect::Connection.new
  def self::connect( server, port, username, password, version )
    return MirthConnect::Connection.new( server, port, username, password, version )
  end


end
