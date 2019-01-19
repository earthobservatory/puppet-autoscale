# azure_public_ipv4.rb
Facter.add("ec2_public_ipv4") do
  setcode do
    %x{curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipaddress/0/publicip?api-version=2017-03-01&format=text"}.chomp
  end
end
