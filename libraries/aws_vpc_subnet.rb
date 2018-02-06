# author: Matthew Dromazos

require '_aws'

class AwsVpcSubnet < Inspec.resource(1)
  name 'aws_vpc_subnet'
  desc 'This resource is used to test the attributes of a VPC subnet'
  example "
    describe aws_vpc_subnet(subnet_id: 'subnet-12345678') do
      it { should exist }
      its('cidr_block') { should eq '10.0.1.0/24' }
    end
  "

  include AwsResourceMixin
  attr_reader :vpc_id, :subnet_id, :cidr_block, :availability_zone, :available_ip_address_count,
              :default_for_az, :map_public_ip_on_launch, :state, :ipv_6_cidr_block_association_set,
              :assign_ipv_6_address_on_creation

  def to_s
    "VPC Subnet #{@subnet_id}"
  end

  private

  def validate_params(raw_params)
    validated_params = check_resource_param_names(
      raw_params: raw_params,
      allowed_params: [:subnet_id],
      allowed_scalar_name: :subnet_id,
      allowed_scalar_type: String,
    )
    
    # Make sure the subnet_id parameter was specified and in the correct form.
    if validated_params.key?(:subnet_id) && validated_params[:subnet_id] !~ /^subnet\-[0-9a-f]{8}/
      raise ArgumentError, 'aws_vpc_subnet Subnet ID must be in the format "subnet-" followed by 8 hexadecimal characters.'
    end

    validated_params
  end

  def fetch_from_aws
    backend = AwsVpcSubnet::BackendFactory.create

    # Transform into filter format expected by AWS
    filters = []
    filters.push({name: 'subnet-id', values: [@subnet_id]})
    ds_response = backend.describe_subnets(filters: filters)

    # If no subnets exist in the VPC, exist is false.
    if ds_response.subnets.empty?
      @exists = false
      return
    end
    @exists = true
    assign_properties(ds_response)
  end

  def assign_properties(ds_response)
    @vpc_id                           = ds_response.subnets[0].vpc_id
    @subnet_id                        = ds_response.subnets[0].subnet_id
    @cidr_block                       = ds_response.subnets[0].cidr_block
    @availability_zone                = ds_response.subnets[0].availability_zone
    @available_ip_address_count       = ds_response.subnets[0].available_ip_address_count
    @default_for_az                   = ds_response.subnets[0].default_for_az
    @map_public_ip_on_launch          = ds_response.subnets[0].map_public_ip_on_launch
    @state                            = ds_response.subnets[0].state
    @ipv_6_cidr_block_association_set = ds_response.subnets[0].ipv_6_cidr_block_association_set
    @assign_ipv_6_address_on_creation = ds_response.subnets[0].assign_ipv_6_address_on_creation
  end

  # Uses the SDK API to really talk to AWS
  class Backend
    class AwsClientApi
      BackendFactory.set_default_backend(self)
      def describe_subnets(query)
        AWSConnection.new.ec2_client.describe_subnets(query)
      end
    end
  end
end
