# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'net/https'
require 'openssl'
require 'uri'
require 'json'
require 'securerandom'
require 'certified'
require_relative '../../../developer_nrel_key'
require 'urbanopt/reopt/reopt_logger'

module URBANopt # :nodoc:
  module REopt  # :nodoc:
    class REoptLiteGHPAPI
              
        def initialize(reopt_input_file, nrel_developer_key = nil, reopt_output_file, use_localhost)
            
            # Store developer key
            if [nil, '', '<insert your key here>'].include? nrel_developer_key
                if [nil, '', '<insert your key here>'].include? DEVELOPER_NREL_KEY
                    raise 'A developer.nrel.gov API key is required. Please see https://developer.nrel.gov/signup/ then update the file urbanopt-reopt-gem/developer_nrel_key.rb'
                else
                    #Store the NREL developer key
                    nrel_developer_key = DEVELOPER_NREL_KEY
                end
            end

            @use_localhost = use_localhost
            if @use_localhost
                @root_url = "http://localhost:8000/stable"
            else
                @root_url = "https://developer.nrel.gov/api/reopt/stable"
            end
            # add REopt URL 
            @nrel_developer_key = nrel_developer_key
            @reopt_input_file = reopt_input_file
            @reopt_output_file = reopt_output_file
            # initialize @@logger
            @@logger ||= URBANopt::REopt.reopt_logger
            @@logger.level = Logger::INFO
        end


        def get_api_results(run_id=nil)
            
            reopt_input_file = @reopt_input_file
            nrel_developer_key = @nrel_developer_key
            root_url = @root_url
            reopt_output_file = @reopt_output_file

            if run_id.nil?
                run_id = get_run_uuid(reopt_input_file, nrel_developer_key, reopt_output_file)
            end
            if !run_id.nil?
                results_url = "#{@root_url}/job/#{run_id}/results/?api_key=#{nrel_developer_key}"
                puts "This is results URL #{results_url}"
                results = reopt_request(results_url)

                File.open(reopt_output_file, 'w') do |f|
                    f.write(JSON.pretty_generate(results))
                    @@logger.info("Saved results to #{reopt_output_file}")
                end
            else
                results = nil
                @@logger.error("Unable to get results: no UUID returned.")
            end
            results
        end

        def get_run_uuid(reopt_input_file, nrel_developer_key, root_url)
            
            reopt_input_file = @reopt_input_file
            nrel_developer_key = @nrel_developer_key
            root_url = @root_url
            post_url = "#{root_url}/job/?api_key=#{nrel_developer_key}"
            puts "This is URL: #{post_url}"
            @@logger.info("Connecting to #{post_url}")
  
            # Parse the URL and prepare the HTTP request
            uri = URI.parse(post_url)
            request = Net::HTTP::Post.new(uri)
            request.content_type = 'application/json'

            # Add the JSON payload (assuming 'post' is the body data)
            request.body = reopt_input_file.to_json
            
            # Send the HTTP request
            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
                http.request(request)
            end

            run_id = nil

            if !response.is_a?(Net::HTTPSuccess)
                @@logger.error("Status code #{response.code}. #{response.body}")
                @@logger.error("Status code #{response.code}")
            else
                @@logger.info("Response OK from #{post_url}.")
                run_id_dict = JSON.parse(response.body)
                
                begin
                    run_id = run_id_dict['run_uuid']
                rescue KeyError
                    msg = "Response from #{post_url} did not contain run_uuid."
                    @@logger.error(msg)
                end
            end
            # Return run_id
            run_id
        end

        def reopt_request(results_url, poll_interval = 5, max_timeout = 300)

            key_error_count = 0
            key_error_threshold = 3
            status = "Optimizing..."
            @@logger.info("Polling #{results_url} for results with interval of #{poll_interval}...")
            resp_dict = {}
            start_time = Time.now

            loop do
                uri = URI.parse(results_url)
                response = Net::HTTP.get_response(uri)
                resp_dict = JSON.parse(response.body)

                begin
                  status = resp_dict['status']
                rescue KeyError
                  key_error_count += 1
                  @@logger.info("KeyError count: #{key_error_count}")
                  if key_error_count > key_error_threshold
                    @@logger.info("Breaking polling loop due to KeyError count threshold of #{key_error_threshold} exceeded.")
                    break
                  end
                end
                
                if status != "Optimizing..."
                    break
                end

                if Time.now - start_time > max_timeout
                    @@logger.info("Breaking polling loop due to max timeout of #{max_timeout} seconds exceeded.")
                    break
                end
                
                sleep(poll_interval)
                
            end
            resp_dict
        end

    #   # Checks if a optimization task can be submitted to the \REopt API
    #   ##
    #   #
    #   # [*parameters:*]
    #   #
    #   # * +data+ - _Hash_ - Default \REopt formatted post containing at least all the required parameters.
    #   #
    #   # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
    #   ##
    #   def check_connection(data)
    #     @uri_submit = URI.parse(@root_url) 
    #     header = { 'Content-Type' => 'application/json' }
    #     http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
    #     puts http
    #     if !@use_localhost
    #       http.use_ssl = true
    #     end

    #     post_request = Net::HTTP::Post.new(@uri_submit, header)
    #     post_request.body = ::JSON.generate(data, allow_nan: true)

    #     # Send the request
    #     response = make_request(http, post_request)

    #     if !response.is_a?(Net::HTTPSuccess)
    #       @@logger.error('Check_connection Failed')
    #       raise 'Check_connection Failed'
    #     end
    #     return true
    #   end

    end
  end
end
