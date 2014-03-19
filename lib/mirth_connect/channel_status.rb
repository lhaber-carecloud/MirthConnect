require 'mirth_connect/helpers'

class MirthConnect::ChannelStatus

  ## Filter Params
  attr_reader :channelId, :name, :state, :deployedRevisionDelta, :deployedDate

  HELPERS = MirthConnect::Helpers

  def initialize( raw_status )

    if raw_status.is_a?(Nokogiri::XML::Element) && raw_status.name == 'channelStatus'
      xml = raw_status
    elsif raw_status.is_a?(String) && raw_status.start_with?('<channelStatus>')
      xml = Nokogiri::XML(raw_status).child
    else
      raise Exception, 'incorrect format for channel status'
    end

    node_set = xml.children

    node_set.each do |element|
      next unless element.is_a?(Nokogiri::XML::Element)

      if element.name.to_sym == :deployedDate
        @deployedDate = Time.at( element.search('time').text.to_i / 1000 )
        @timezone    = element.search('timezone').text
      else
        instance_variable_set("@#{element.name}", element.text)
      end

    end

  end

  def [](key)
    instance_variable_get("@#{key.to_s}")
  end

end
