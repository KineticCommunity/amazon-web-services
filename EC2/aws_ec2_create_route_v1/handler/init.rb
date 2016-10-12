require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AwsEc2CreateRouteV1

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

    targets=[]
    [@parameters['gateway_id'],@parameters['instance_id'],@parameters['network_interface_id'],@parameters['vpc_peering_connection_id']].each{ |target|
      if target.strip!=""
        targets.push(target)
      end
    }

    puts targets if @enable_debug_logging

    if  targets.length == 0
      raise ("'Gateway ID', 'NAT Instance ID', 'VPC Peering Connection ID', or 'Network Interface ID' must be provided.")
    end 

    if targets.length > 1
      raise ("Onle one of 'Gateway ID', 'NAT Instance ID', 'VPC Peering Connection ID', or 'Network Interface ID' can be provided.")
    end


    resp = @ec2.create_route(
      dry_run: @parameters['dry_run'],
      route_table_id: @parameters['route_table_id'],
      destination_cidr_block: @parameters['destination_cidr_block'],
      gateway_id: @parameters['gateway_id'],
      instance_id: @parameters['instance_id'],
      network_interface_id: @parameters['network_interface_id'],
      vpc_peering_connection_id: @parameters['vpc_peering_connection_id']
    )

    message="Successfully added route to route table #{@parameters['route_table_id']}"

    <<-RESULTS
    <results>
      <result name="message">#{escape(message)}</result>
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
