class MirthConnect::Helpers
  class << self

    def validate_message_filter(filter)

      return false if filter.length > 1 || filter[:filter].nil?

      valid_filter = filter[:filter].select do |key, value|
        if message_filter_params.include?(key.to_sym)
          case key.to_sym
            when :startDate || :endDate
              (value.is_a?(Hash) && value.length == 2 && value.keys == [:time, :timezone])
            when :status
              (value.is_a?(String) && status_params.include?(value))
            when :protocol
              (value.is_a?(String) && protocol_params.include?(value))
            else
              true
          end
        else
          false
        end
      end
      {:filter => valid_filter}
    end

    def unix_13_digit_time ( time )
      (time.to_f * 1000).to_i
    end

    def status_params
      %w[ UNKNOWN RECEIVED ACCEPTED FILTERED TRANSFORMED ERROR SENT QUEUED ]
    end

    def protocol_params
      %w[ HL7V2 X12 XML HL7V3 EDI NCPDP DICOM DELIMITED ]
    end

    def channel_status_params
      [:channelId,              # String
       :name,                   # String
       :state,                  # String
       :deployedRevisionDelta,  # String
       :deployedDate ]          # Hash   {:time => (13-Digit UNIX), :timezone => America/New_York}


    end

    def message_filter_params
      [:id,                    # String
       :correlationId,         # String
       :channelId,             # String
       :startDate,             # Hash   {:time => (13-Digit UNIX), :timezone => America/New_York}
       :endDate,               # Hash   {:time => (13-Digit UNIX), :timezone => America/New_York}
       :status,                # String [ UNKNOWN, RECEIVED, ACCEPTED, FILTERED, TRANSFORMED, ERROR, SENT, QUEUED ]
       :connectorName,         # String
       :searchRawData,         # Boolean
       :searchTransformedData, # Boolean
       :searchEncodedData,     # Boolean
       :searchErrors,          # Boolean
       :quickSearch,           # String
       :searchCriteria,        # String
       :type,                  # String
       :protocol,              # String [ HL7V2, X12, XML, HL7V3, EDI, NCPDP, DICOM, DELIMITED ]
       :ignoredQueued,         # Boolean
       :channelIdList        ] # Array  [String, String, String]
    end

    def message_object_params
      [:id,                      # String
       :serverId,                # String
       :channelId,               # String
       :source,                  # String
       :type,                    # String
       :status,                  # String  [ UNKNOWN, RECEIVED, ACCEPTED, FILTERED, TRANSFORMED, ERROR, SENT, QUEUED ]
       :dateCreated,             # Hash    {:time => (13-Digit UNIX), :timezone => America/New_York}
       :rawData,                 # String
       :rawDataProtocol,         # String  [ HL7V2, X12, XML, HL7V3, EDI, NCPDP, DICOM, DELIMITED ]
       :transformedData,         # String
       :transformedDataProtocol, # String  [ HL7V2, X12, XML, HL7V3, EDI, NCPDP, DICOM, DELIMITED ]
       :encodedDataProtocol,     # String  [ HL7V2, X12, XML, HL7V3, EDI, NCPDP, DICOM, DELIMITED ]
       :connectorName,           # String
       :encrypted,               # Boolean
       :errors,                  # String
       :version,                 # String
       :correlationId,           # String
       :attachment,              # String
       :connectorMap,            # Array   [ {entry => [String, String]}, {entry => [String, String]} ]
       :responseMap,             # Array   [ {entry => [String, String]}, {entry => [String, String]} ]
       :channelMap,              # Array   [ {entry => [String, String]}, {entry => [String, String]} ]
       :context                ]
    end

 end
end