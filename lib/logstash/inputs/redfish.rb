# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require "rest-client"
require "json" 
require 'base64'
# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Redfish < LogStash::Inputs::Base
  config_name "redfish"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # TODO: Validations
  config :ip, :validate => :string, :default => "127.0.0.1", :required => true
  config :api_user, :validate => :string, :default => "", :required => true
  config :api_key, :validate => :string, :default => "", :required => true
  config :types, :validate => :array, :default => [], :required => true
  config :slash, :validate => :boolean, :default => true
  config :timeout, :validate => :number, :default => 10
  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 50

  public

  def query(slug="/redfish")
    response = RestClient::Request.execute(:url => @url+slug, :method => :get, :verify_ssl => false, timeout: @timeout, :headers => {:Authorization => @auth})
    JSON.parse(response.body)
  end

  def register
   #Normalize types
   @types = @types.map(&:downcase).map(&:to_sym)
   @url="https://#{@ip}"
   @urls = Hash.new
   @info_urls_retrieve = false 
   @auth = 'Basic ' + Base64.encode64( "#{@api_user}:#{@api_key}" ).chomp
  end

  def get_info_urls
   @info_urls_retrieve = false
   # Retrieving URLs to query from the redfish server
   begin 
     data = query(query["v1"])
     @urls[:systems] = query(data["Systems"]["@odata.id"])["Members"].first["@odata.id"]
     @urls[:chassis] = query(data["Chassis"]["@odata.id"])["Members"].first["@odata.id"]
     @urls[:power] = query(@urls[:chassis])["Power"]["@odata.id"]
     @urls[:thermal] = query(@urls[:chassis])["Thermal"]["@odata.id"]
     @info_urls_retrieve = true
   rescue => e
     @logger.error("Redfish: cannot retrieve info urls #{@ip} e = "+e.to_s)
   end
  end # def register

  def run(queue)
    # we can abort the loop if stop? becomes truei
    while !stop?    
      if @info_urls_retrieve 
        @types.each do |type|
          next unless @urls.key?type      
          begin 
            response = query(@urls[type])

            @codec.decode(response.to_json) do | event |
              decorate(event)
              event.set("ip", @ip)
              event.set("type",type)
              queue << event
            end
         rescue => e
           @logger.error("Redfish could not retrieve data from ip #{@ip}") 
         end
        end
      else
        get_info_urls
      end # info_urls_retrieve
      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end # def run

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
  end
end # class LogStash::Inputs::Example
