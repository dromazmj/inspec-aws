fixtures = {}
[
  'ec2_security_group_default_vpc_id',
  'ec2_security_group_default_group_id',
  'ec2_security_group_alpha_group_id',
  'ec2_security_group_allow_all_group_id',
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/ec2.tf',
  )
end

control "aws_ec2_security_group recall of default VPC" do

  describe aws_ec2_security_group(fixtures['ec2_security_group_default_group_id']) do
    it { should exist }
  end

  describe aws_ec2_security_group(group_name: 'default', vpc_id: fixtures['ec2_security_group_default_vpc_id']) do
    it { should exist }
  end

  describe aws_ec2_security_group(group_name: 'no-such-security-group') do
    it { should_not exist }
  end
end

control "aws_ec2_security_group properties" do
  # You should be able to find the default security group's ID.
  describe aws_ec2_security_group(fixtures['ec2_security_group_default_group_id']) do
    its('group_id') { should cmp fixtures['ec2_security_group_default_group_id'] }
  end

  describe aws_ec2_security_group(fixtures['ec2_security_group_alpha_group_id']) do
    its('group_name') { should cmp 'alpha' }
    its('vpc_id') { should cmp  fixtures['ec2_security_group_default_vpc_id'] }
    its('description') { should cmp 'SG alpha' }
  end

end

control "aws_ec2_security_group ingress_rules port 22 open" do
  describe aws_ec2_security_group(fixtures['ec2_security_group_allow_all_group_id']) do
    it { should_not be_open_on_port(22) }
  end
end

control "aws_ec2_security_group ingress_rules port 3389 open" do
  describe aws_ec2_security_group(fixtures['ec2_security_group_allow_all_group_id']) do
    it { should_not be_open_on_port(3389) }
  end
end

control "aws_ec2_security_group ingress_rules properties" do
  describe aws_ec2_security_group(fixtures['ec2_security_group_allow_all_group_id']).where(from_port: 0, to_port: 65535) do
    its('to_port') { should eq [65535] }
  end
end
