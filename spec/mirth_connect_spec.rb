require 'mirth_connect'

describe MirthConnect do
  it "should create connection" do
    mirth = MirthConnect.connect('192.168.123.227', '8443', 'monitoring_service', 'C4r3Cl0ud', '2.2.3.6825')
    !mirth.cookie.nil?
  end
  it "should NOT get cookie with bad login" do
    mirth = MirthConnect.connect('192.168.123.227', '8443', 'monitoring_service', 'bad_data', '2.2.3.6825')
    mirth.cookie.nil?
  end

  it "should find message with good message id" do
    mirth = MirthConnect.connect('192.168.123.227', '8443', 'monitoring_service', 'C4r3Cl0ud', '2.2.3.6825')
    mirth.get_message_by_id('da3233b2-4089-43be-8d81-737b2f0889de')
  end
end