require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AwsEc2CreateNetworkInterfaceV1

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
    
    inputs={}
    inputs[:dry_run] = @parameters['dry_run']
    inputs[:subnet_id] = @parameters['subnet_id']
    inputs[:description] = @parameters['description']
    inputs[:private_ip_address] = @parameters['private_ip_address'] if @parameters['private_ip_address'].strip!=""    
    inputs[:secondary_private_ip_address_count] = @parameters['secondary_private_ip_address_count'].to_i if @parameters['secondary_private_ip_address_count'].strip!=""

    groups_array = []
    @parameters['groups'].split(",").each { |group|
      groups_array.push(group.strip)
    }
    # populate the inputs with groups if any were submitted
    inputs[:groups] = groups_array if groups_array.length > 0

    pipaddr_array = []
    if @parameters['private_ip_addresses'].strip != ""
      begin
        pipaddr_json = JSON.parse(@parameters['private_ip_addresses'])
      rescue Exception => e
        raise "Error parsing private_ip_addresses structure: #{@parameters['private_ip_addresses']} \n\n#{e.message}"
      end
    end
    # populate the inputs with owners if any were submitted
    inputs[:private_ip_addresses] = pipaddr_array if pipaddr_array.length > 0

    puts inputs if @enable_debug_logging

    resp = @ec2.create_network_interface(inputs)

    puts resp.network_interface if @enable_debug_logging

    attachment_details = {}
    if !resp.network_interface.attachment.nil?
      attachment_details['attachment_id'] = resp.network_interface.attachment.attachment_id
      attachment_details['instance_id'] = resp.network_interface.attachment.instance_id
      attachment_details['instance_owner_id'] = resp.network_interface.attachment.instance_owner_id
      attachment_details['device_index'] = resp.network_interface.attachment.device_index
      attachment_details['status'] = resp.network_interface.attachment.status
      attachment_details['attach_time'] = resp.network_interface.attachment.attach_time.strftime("%Y-%m-%dT%e:%M:%S%z")
      attachment_details['delete_on_termination'] = resp.network_interface.attachment.delete_on_termination
    end

    association_details = {}
    if !resp.network_interface.association.nil?
      attachment['public_ip'] = resp.network_interface.association.public_ip
      attachment['public_dns_name'] = resp.network_interface.association.public_dns_name
      attachment['ip_owner_id'] = resp.network_interface.association.ip_owner_id
      attachment['allocation_id'] = resp.network_interface.association.allocation_id
      attachment['association_id'] = resp.network_interface.association.association_id
    end

      # The attachment and association properties may be nil.  If so these will fail.  Need to parse them differently.
      #<result name="attachment_attachment_id">#{escape(resp.network_interface.attachment.attachment_id)}</result>
      #<result name="attachment_instance_id">#{escape(resp.network_interface.attachment.instance_id)}</result>
      #<result name="attachment_instance_owner_id">#{escape(resp.network_interface.attachment.instance_owner_id)}</result>
      #<result name="attachment_device_index">#{escape(resp.network_interface.attachment.device_index)}</result>
      #<result name="attachment_status">#{escape(resp.network_interface.attachment.status)}</result>
      #<result name="attachment_attach_time">#{escape(resp.network_interface.attachment.attach_time.strftime("%Y-%m-%dT%e:%M:%S%z"))}</result>
      #<result name="attachment_delete_on_termination">#{escape(resp.network_interface.attachment.delete_on_termination)}</result>
      #<result name="association_public_ip">#{escape(resp.network_interface.association.public_ip)}</result>
      #<result name="association_public_dns_name">#{escape(resp.network_interface.association.public_dns_name)}</result>
      #<result name="association_ip_owner_id">#{escape(resp.network_interface.association.ip_owner_id)}</result>
      #<result name="association_allocation_id">#{escape(resp.network_interface.association.allocation_id)}</result>
      #<result name="association_association_id">#{escape(resp.network_interface.association.association_id)}</result>

    <<-RESULTS
    <results>
      <result name="network_interface_id">#{escape(resp.network_interface.network_interface_id)}</result>
      <result name="subnet_id">#{escape(resp.network_interface.subnet_id)}</result>
      <result name="vpc_id">#{escape(resp.network_interface.vpc_id)}</result>
      <result name="availability_zone">#{escape(resp.network_interface.availability_zone)}</result>
      <result name="description">#{escape(resp.network_interface.description)}</result>
      <result name="owner_id">#{escape(resp.network_interface.owner_id)}</result>
      <result name="requester_id">#{escape(resp.network_interface.requester_id)}</result>
      <result name="requester_managed">#{escape(resp.network_interface.requester_managed)}</result>
      <result name="status">#{escape(resp.network_interface.status)}</result>
      <result name="mac_address">#{escape(resp.network_interface.mac_address)}</result>
      <result name="private_ip_address">#{escape(resp.network_interface.private_ip_address)}</result>
      <result name="private_dns_name">#{escape(resp.network_interface.private_dns_name)}</result>
      <result name="source_dest_check">#{escape(resp.network_interface.source_dest_check)}</result>
      <result name="groups">#{escape(resp.network_interface.groups.to_s)}</result>
     
      <result name="attachment_attachment_id">#{escape(attachment_details["attachment_id"])}</result>
      <result name="attachment_instance_id">#{escape(attachment_details["instance_id"])}</result>
      <result name="attachment_instance_owner_id">#{escape(attachment_details["instance_owner_id"])}</result'>
      <result name="attachment_device_index">#{escape(attachment_details["device_index"])}</result>
      <result name="attachment_status">#{escape(attachment_details["status"])}</result>
      <result name="attachment_attach_time">#{escape(attachment_details["attach_time"])}</result>
      <result name="attachment_delete_on_termination">#{escape(attachment_details["delete_on_termination"])}</result>

      <result name="association_public_ip">#{escape(association_details["public_ip"])}</result>
      <result name="association_public_dns_name">#{escape(association_details["public_dns_name"])}</result>
      <result name="association_ip_owner_id">#{escape(association_details["ip_owner_id"])}</result>
      <result name="association_allocation_id">#{escape(association_details["allocation_id"])}</result>
      <result name="association_association_id">#{escape(association_details["association_id"])}</result>

      <result name="tag_set">#{escape(resp.network_interface.tag_set.to_s)}</result>
      <result name="private_ip_addresses">#{escape(resp.network_interface.private_ip_addresses.to_s)}</result>
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
