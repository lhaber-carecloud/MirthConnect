class MirthConnect::Helpers
  class << self

    def unix_13_digit_time ( time )
      time = time.to_time if time.is_a?(Date)
      (time.to_f * 1000).to_i
    end

    def status_params
      %w[ UNKNOWN RECEIVED ACCEPTED FILTERED TRANSFORMED ERROR SENT QUEUED ]
    end

    def protocol_params
      %w[ HL7V2 X12 XML HL7V3 EDI NCPDP DICOM DELIMITED ]
    end

 end
end