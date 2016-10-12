require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AwsEc2CreateSubnetV1

  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)
    
    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") { |item|
      @info_values[item.attributes['name']] = item.text  
    }
    
    # Retrieve all of the handler parameters and store them in a hash attribute
    # named @parameters.
    @parameters = {}
    REXML::XPath.match(@input_document, 'handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s
    end

    @enable_debug_logging = @info_values['enable_debug_logging'] == 'Yes'
    puts "#{@parameters}" if @enable_debug_logging
    
    # Retrieve the credentials for the AWS session from the input XML string
    creds = Aws::Credentials.new(@info_values['access_key_id'], @info_values['secret_access_key'])
    
    # Create a base AWS object. This object contains all the methods for accessing
    # Amazon Web Services
    @ec2 = Aws::EC2::Client.new(
      region: @info_values['region'],
      credentials: creds
    )

  end
  
  def execute() 
 
    resp = @ec2.create_subnet(
      dry_run: @parameters['dry_run'],
      vpc_id: @parameters['vpc_id'],
      cidr_block: @parameters['cidr_block'],
      availability_zone: @parameters['availability_zone']
    )

    puts resp.subnet if @enable_debug_logging

    <<-RESULTS
    <results>
      <result name="subnet_id">#{escape(resp.subnet.subnet_id)}</result>
      <result name="subnet_state">#{escape(resp.subnet.state)}</result>
      <result name="subnet_vpc_id">#{escape(resp.subnet.vpc_id)}</result>
      <result name="subnet_cidr_block">#{escape(resp.subnet.cidr_block)}</result>
      <result name="subnet_available_ip_address_count">#{escape(resp.subnet.available_ip_address_count)}</result>
      <result name="subnet_availability_zone">#{escape(resp.subnet.availability_zone)}</result>
      <result name="subnet_default_for_az">#{escape(resp.subnet.default_for_az)}</result>
      <result name="subnet_map_public_ip_on_launch">#{escape(resp.subnet.map_public_ip_on_launch)}</result>
      <result name="subnet_tags">#{escape(resp.subnet.tags.to_s)}</result>
    </results>
    RESULTS
  end
  
  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
