# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AmazonS3ExpiringUrlGeneratorV1
  # Prepare for execution by building Hash objects for necessary data and
  # configuration values, and validating the present state.  This method
  # sets the following instance variables:
  # * @input_doc - A REXML::Document object that represents the input XML.
  # * @info_values - A hash object that represents the info values.
  # * @parameters - A hash object that represents the current parameter values.
  # * @enable_debug_logging - A boolean used to determine whether or not to
  #   output debug logging
  #
  # This is a required method that is automatically called by the Kinetic Task
  # Engine.
  #
  # ==== Parameters
  # * +input+ - The String of Xml that was built by evaluating the node.xml
  #   handler template.
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
  end

  #
  # This is a required method that is automatically called by the Kinetic Task
  # Engine.
  #
  # ==== Returns
  # An XML formatted String representing the return variable results.
  def execute()
    s3 = Aws::S3::Client.new(access_key_id: @info_values['access_key_id'],
          secret_access_key: @info_values['secret_access_key'],
          region: @parameters['region'])

    signer = Aws::S3::Presigner.new( {client: s3} )

    seconds_to_expire_int = @parameters['seconds_to_expire'].to_i

    url = signer.presigned_url(:get_object, bucket: @parameters['bucket'], key: @parameters['key'], expires_in: seconds_to_expire_int )

    # Build the results XML that will be returned by this handler.
    <<-RESULTS
      <results>
          <result name="Public Url">#{escape(url)}</result>
      </results>
    RESULTS
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

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
