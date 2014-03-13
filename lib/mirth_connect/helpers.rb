class MirthConnect::Helpers
  class << self

    def validate_message_filter(filter)
      valid_filter = filter.select{|f| message_filter_params.include?(f.to_sym) }
      valid_filter
    end

    def unix_13_digit_time ( time )
      (time.to_f * 1000).to_i
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