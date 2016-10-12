require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AwsEc2DescribeAvailabilityZonesV1

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
 
    zone_names_array = []
    @parameters['zone_names'].split(",").each {|zone|
      zone_names_array.push(zone.strip)
    }

    puts zone_names_array if @enable_debug_logging

    if zone_names_array.length > 0 
      resp = @ec2.describe_availability_zones(
        dry_run: @parameters['dry_run'],
        zone_names: zone_names_array
      )
    else
      resp = @ec2.describe_availability_zones(
        dry_run: @parameters['dry_run']
      )
    end

    puts resp.availability_zones if @enable_debug_logging

    availability_zone_xml = "<zones>\n"
    resp.availability_zones.each do |zone|
      availability_zone_xml << "<zone name=\"#{zone['zone_name']}\">\n"
        availability_zone_xml << "<zone_name>" << zone['zone_name'] << "</zone_name>\n"
        availability_zone_xml << "<state>" << zone['state'] << "</state>\n"
        availability_zone_xml << "<region_name>" << zone['region_name'] << "</region_name>\n" 
        availability_zone_xml << "<messages>\n" 
        zone['messages'].each do |message|
          availability_zone_xml << "<message>" << message['message'] << "</message>\n" 
        end
        availability_zone_xml << "</messages>\n"
      availability_zone_xml << "</zone>\n"
    end
    availability_zone_xml << "</zones>"

    puts "Availability Zone XML" if @enable_debug_logging
    puts availability_zone_xml if @enable_debug_logging


    zone_names_array=[]
    resp.availability_zones.each do |zone_info|
      zone_names_array.push(zone_info['zone_name'])
    end


    return_xml = "<results>\n"
    return_xml += "<result name='availability_zone_info_xml'>#{escape(availability_zone_xml)}</result>\n"
    return_xml += "<result name='availability_zone_info_string'>#{escape(zone_names_array.join(","))}</result>\n"

    resp.availability_zones.each do |zone_info|
      return_xml += "<result name='#{escape(zone_info['zone_name'])}'>#{escape(zone_info['zone_name'])}</result>\n"
    end

    return_xml += "</results>"

    puts "Return XML" if @enable_debug_logging
    puts return_xml if @enable_debug_logging

    return return_xml

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
