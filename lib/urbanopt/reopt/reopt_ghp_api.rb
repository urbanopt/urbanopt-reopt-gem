# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'net/https'
require 'openssl'
require 'uri'
require 'json'
require 'securerandom'
require_relative '../../../developer_api_key'
require 'urbanopt/reopt/reopt_logger'
require 'urbanopt/reopt/url_config'

module URBANopt # :nodoc:
  module REopt  # :nodoc:
    class REoptGHPAPI

        def initialize(reopt_input_file, api_key = nil, reopt_output_file)

            # Store developer key
            if [nil, '', '<insert your key here>'].include? api_key
                if [nil, '', '<insert your key here>'].include? DEVELOPER_API_KEY
                    # Check if we need an API key based on the URL that will be used
                    url_config_test = URLConfig.new
                    if url_config_test.requires_api_key?
                        raise 'A developer.nlr.gov API key is required. Please see https://developer.nlr.gov/signup/ then update the file developer_api_key.rb'
                    end
                else
                    api_key = DEVELOPER_API_KEY
                end
            end

            # Initialize URL configuration
            @url_config = URLConfig.new(api_key: api_key)

            # Store for backward compatibility
            @root_url = @url_config.base_url
            @api_key = api_key
            @reopt_input_file = reopt_input_file
            @reopt_output_file = reopt_output_file
            # initialize @@logger
            @@logger ||= URBANopt::REopt.reopt_logger
            @@logger.level = Logger::INFO
        end


        def get_api_results(run_id=nil)

            reopt_input_file = @reopt_input_file
            api_key = @api_key
            root_url = @root_url
            reopt_output_file = @reopt_output_file

            if run_id.nil?
                run_id = get_run_uuid
            end
            if !run_id.nil?
                results_url = @url_config.url_for('job', run_uuid: run_id)
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

        def get_run_uuid
            post_url = @url_config.url_for('job')
            @@logger.info("Connecting to #{post_url}")

            # Parse the URL and prepare the HTTP request
            uri = URI.parse(post_url)
            request = Net::HTTP::Post.new(uri)
            request.content_type = 'application/json'

            # Add the JSON payload (assuming 'post' is the body data)
            request.body = @reopt_input_file.to_json

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

        def reopt_request(results_url, poll_interval = 5, max_timeout = 600)

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

    end
  end
end
