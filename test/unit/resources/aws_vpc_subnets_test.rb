require 'ostruct'
require 'helper'
require 'aws_vpc_subnets'

# MVSB = MockVpcSubnetsBackend
# Abbreviation not used outside this file

#=============================================================================#
#                            Constructor Tests
#=============================================================================#
class AwsVpcSubnetsConstructor < Minitest::Test
  def setup
    AwsVpcSubnets::BackendFactory.select(AwsMVSB::Empty)
  end

  def test_constructor_no_args_ok
    AwsVpcSubnets.new
  end

  def test_constructor_reject_unknown_resource_params
    assert_raises(ArgumentError) { AwsVpcSubnets.new(bla: 'blabla') }
  end
end

#=============================================================================#
#                            Filter Criteria
#=============================================================================#
class AwsVpcSubnetsFilterCriteria < Minitest::Test
  def setup
    AwsVpcSubnets::BackendFactory.select(AwsMVSB::Basic)
  end

  def test_filter_vpc_id
    hit = AwsVpcSubnets.new.where(vpc_id: 'vpc-01234567')
    assert(hit.exists?)

    miss = AwsVpcSubnets.new.where(vpc_id: 'vpc-87654321')
    refute(miss.exists?)

  end

  def test_filter_subnet_id
    hit = AwsVpcSubnets.new.where(subnet_id: 'subnet-01234567')
    assert(hit.exists?)

    miss = AwsVpcSubnets.new.where(group_name: 'subnet-98765432')
    refute(miss.exists?)
  end

end

#=============================================================================#
#                            Properties
#=============================================================================#
class AwsVpcSubnetProperties < Minitest::Test
  def setup
    AwsVpcSubnets::BackendFactory.select(AwsMVSB::Basic)
  end

  def test_property_cidr_block
    basic = AwsVpcSubnets.new
    assert_kind_of(Array, basic.cidr_blocks)
    assert(basic.cidr_blocks.include?('10.0.1.0/24'))
    refute(basic.cidr_blocks.include?(nil))
  end
end

#=============================================================================#
#                               Test Fixtures
#=============================================================================#

module AwsMVSB
  class Empty < AwsVpcSubnets::Backend
    def describe_subnets(_query)
      OpenStruct.new({
        subnets: [],
      })
    end
  end

  class Basic < AwsVpcSubnets::Backend
    def describe_subnets(query)
      fixtures = [
        OpenStruct.new({
          availability_zone: "us-east-1c",
          available_ip_address_count: 251,
          cidr_block: "10.0.1.0/24",
          default_for_az: false,
          map_public_ip_on_launch: false,
          state: "available",
          subnet_id: "subnet-01234567",
          vpc_id: "vpc-01234567",
        }),
        OpenStruct.new({
          availability_zone: "us-east-1b",
          available_ip_address_count: 251,
          cidr_block: "10.0.2.0/24",
          default_for_az: false,
          map_public_ip_on_launch: false,
          state: "available",
          subnet_id: "subnet-00112233",
          vpc_id: "vpc-00112233",
        }),
      ]

      selected = fixtures.select do |sg|
        query.keys.all? do |criterion|
          query[criterion] == sg[criterion]
        end
      end

      OpenStruct.new({ subnets: selected })
    end
  end

end