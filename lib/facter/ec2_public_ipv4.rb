# ec2_public_ipv4.rb
# this is temporarily functionally identical to azure_public_ipv4 as the
# contributor is unclear how this script integrates into the rest of the system
Facter.add("ec2_public_ipv4") do
  setcode do
    #%x{curl -s http://169.254.169.254/latest/meta-data/public-ipv4}.chomp
    %x{curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipaddress/0/publicip?api-version=2017-03-01&format=text"}.chomp
  end
end
