require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AwsEc2CreateInternetGatewayV1

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
 
    resp = @ec2.create_internet_gateway(
      dry_run: @parameters['dry_run']
    )

    puts resp.internet_gateway if @enable_debug_logging

    ig_attachments=[]
    resp.internet_gateway.attachments.each { |attachment|
      ig_attachments.push({"vpc_id" => attachment.vpc_id, "state" => attachment.state})
    }

    ig_tags=[]
    resp.internet_gateway.tags.each { |tag|
      ig_tags.push({"key" => tag.key, "value" => tag.value})
    }

    <<-RESULTS
    <results>
      <result name="internet_gateway_id">#{escape(resp.internet_gateway.internet_gateway_id)}</result>
      <result name="internet_gateway_attachments">#{escape(ig_attachments.to_s)}</result>
      <result name="internet_gateway_tags">#{escape(ig_tags.to_s)}</result>
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
