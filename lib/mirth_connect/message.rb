require 'mirth_connect/helpers'

class MirthConnect::Message

  ## Message Params
  attr_accessor :id,
                :serverId,
                :channelId,
                :source,
                :type,
                :status,
                :dateCreated,
                :rawData,
                :rawDataProtocol,
                :transformedData,
                :transformedDataProtocol,
                :encodedDataProtocol,
                :connectorName,
                :encrypted,
                :errors,
                :version,
                :correlationId,
                :attachment,
                :connectorMap,
                :responseMap,
                :channelMap,
                :context

  attr_accessor :timezone

  HELPERS = MirthConnect::Helpers

  def initialize(raw_message)

    if raw_message.is_a?(Nokogiri::XML::Element) && raw_message.name == 'messageObject'
      xml = raw_message
    elsif raw_message.is_a?(String) && raw_message.start_with?('<messageObject>')
      xml = Nokogiri::XML(raw_message).child
    else
      raise Exception, 'incorrect format for message'
    end

    node_set = xml.children

    node_set.each do |element|

      next unless element.is_a?(Nokogiri::XML::Element)

      case element.name.to_sym
        when :dateCreated
          @dateCreated = Time.at( element.search('time').text.to_i / 1000 )
          @timezone    = element.search('timezone').text
        when :encrypted
          element.text == 'true' ? true : false
        when :channelMap, :responseMap, :connectorMap
          map = Array.new
          element.search('entry').each do |entry|
            next unless entry.is_a?(Nokogiri::XML::Element)
            strings = entry.children.select{|child| child.is_a?(Nokogiri::XML::Element)}
            map << {strings[0] => strings[1]}
          end
          instance_variable_set("@#{element.name}", map)
        else
          instance_variable_set("@#{element.name}", element.text)
      end
    end
  end

  def to_xml_string

    xml = '<messageObject>'

    instance_variables.each do |var|

      var_string = var.to_s.delete('@')

      case var_string.to_sym
        when :dateCreated
          xml << "<#{var_string}>"

          xml << '<time>'
          xml << HELPERS.unix_13_digit_time( instance_variable_get( var ) ).to_s
          xml << '</time>'

          xml << '<timezone>'
          xml << @timezone
          xml << '</timezone>'

          xml << "</#{var_string}>"
        when :channelMap, :responseMap, :connectorMap
          xml << "<#{var_string}>"
          instance_variable_get( var ).each do |s1, s2|
            xml << '<entry>'
            xml << "<string>#{s1}</string>"
            xml << "<string>#{s2}</string>"
            xml << '</entry>'
          end
          xml << "</#{var_string}>"
        when :timezone
          #ignored
        else
          xml << "<#{var_string}>"
          xml << instance_variable_get( var ).to_s.encode(:xml => :attr)
          xml << "/<#{var_string}>"
      end
    end

    xml << '</messageObject>'

    xml
  end

  def [](key)
    instance_variable_get("@#{key.to_s}")
  end

  def []=(key,value)
    instance_variable_set("@#{key.to_s}", value)
  end
end
