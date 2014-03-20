require 'mirth_connect/helpers'

class MirthConnect::Filter

  ## Filter Params
  attr_accessor :id, :channelId, :status, :startDate, :endDate

  attr_accessor :timezone

  HELPERS = MirthConnect::Helpers

  def initialize( opts = {} )

    @timezone = opts[:timezone] ? opts[:timezone] : 'America/New York'

    @id        = opts[:id]        if opts[:id]
    @channelId = opts[:channelId] if opts[:channelId]
    @status    = opts[:status]    if opts[:status]    && HELPERS.status_params.include?(opts[:status])

    @startDate = opts[:startDate] if opts[:startDate]
    @endDate   = opts[:endDate] if opts[:endDate]

  end

  def to_xml_string

    xml = '<messageObjectFilter>'

    instance_variables.each do |var|

      var_string = var.to_s.delete('@')

      case var_string.to_sym
        when :startDate, :endDate
          xml << "<#{var_string}>"
          xml << '<time>'
          xml << HELPERS.unix_13_digit_time( instance_variable_get( var ) ).to_s
          xml << '</time>'

          xml << '<timezone>'
          xml << @timezone
          xml << '</timezone>'
          xml << "</#{var_string}>"
        when :timezone
          #ignored
        else
          xml << "<#{var_string}>"
          xml << instance_variable_get( var ).to_s
          xml << "</#{var_string}>"
      end
    end

    xml << '</messageObjectFilter>'

    xml
  end

  def [](key)
    instance_variable_get("@#{key.to_s}")
  end

  def []=(key,value)
    instance_variable_set("@#{key.to_s}", value)
  end

  class << self

    def today( filter = {} )
      filter = filter.merge({:startDate => Date.today})
      self.new( filter )
    end

    def yesterday( filter = {} )
      filter = filter.merge({:startDate => Date.yesterday, :endDate => Date.today})
      self.new( filter )
    end

  end
end