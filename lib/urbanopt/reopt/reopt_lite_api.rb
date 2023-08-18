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
    class REoptLiteAPI
      ##
      # \REoptLiteAPI manages submitting optimization tasks to the \REopt API  and recieving results.
      # Results can either be sourced from the production \REopt API with an API key from developer.nrel.gov, or from
      # a version running at localhost.
      ##
      #
      # [*parameters:*]
      #
      # * +use_localhost+ - _Bool_ - If this is true, requests will be sent to a version of the \REopt API running on localhost. Default is false, such that the production version of \REopt is accessed.
      # * +nrel_developer_key+ - _String_ - API key used to access the \REopt APi. Required only if localhost is false. Obtain from https://developer.nrel.gov/signup/
      ##
      def initialize(nrel_developer_key = nil, use_localhost = false)
        @use_localhost = use_localhost
        if @use_localhost
          @uri_submit = URI.parse('http//:127.0.0.1:8000/v2/job/')
          @uri_submit_outagesimjob = URI.parse('http//:127.0.0.1:8000/v2/outagesimjob/')
        else
          if [nil, '', '<insert your key here>'].include? nrel_developer_key
            if [nil, '', '<insert your key here>'].include? DEVELOPER_NREL_KEY
              raise 'A developer.nrel.gov API key is required. Please see https://developer.nrel.gov/signup/ then update the file urbanopt-reopt-gem/developer_nrel_key.rb'
            else
              nrel_developer_key = DEVELOPER_NREL_KEY
            end
          end
          @nrel_developer_key = nrel_developer_key
          @uri_submit = URI.parse("https://developer.nrel.gov/api/reopt/v2/job?api_key=#{@nrel_developer_key}")
          @uri_submit_outagesimjob = URI.parse("https://developer.nrel.gov/api/reopt/v2/outagesimjob?api_key=#{@nrel_developer_key}")
          # initialize @@logger
          @@logger ||= URBANopt::REopt.reopt_logger
        end
      end

      ##
      # URL of the results end point for a specific optimization task
      ##
      #
      # [*parameters:*]
      #
      # * +run_uuid+ - _String_ - Unique run_uuid obtained from the \REopt job submittal URL for a specific optimization task.
      #
      # [*return:*] _URI_ - Returns URI object for use in calling the \REopt results endpoint for a specifc optimization task.
      ##
      def uri_results(run_uuid) # :nodoc:
        if @use_localhost
          return URI.parse("http://127.0.0.1:8000/v2/job/#{run_uuid}/results")
        end

        return URI.parse("https://developer.nrel.gov/api/reopt/v2/job/#{run_uuid}/results?api_key=#{@nrel_developer_key}")
      end

      ##
      # URL of the resilience statistics end point for a specific optimization task
      ##
      #
      # [*parameters:*]
      #
      # * +run_uuid+ - _String_ - Resilience statistics for a unique run_uuid obtained from the \REopt job submittal URL for a specific optimization task.
      #
      # [*return:*] _URI_ - Returns URI object for use in calling the \REopt resilience statistics endpoint for a specifc optimization task.
      ##
      def uri_resilience(run_uuid) # :nodoc:
        if @use_localhost
          return URI.parse("http://127.0.0.1:8000/v2/job/#{run_uuid}/resilience_stats")
        end

        return URI.parse("https://developer.nrel.gov/api/reopt/v2/job/#{run_uuid}/resilience_stats?api_key=#{@nrel_developer_key}")
      end

      def make_request(http, req, max_tries = 3)
        result = nil
        tries = 0
        while tries < max_tries
          begin
            result = http.request(req)
            # Result codes sourced from https://developer.nrel.gov/docs/errors/
            if result.code == '429'
              @@logger.fatal('Exceeded the REopt API limit of 300 requests per hour')
              puts 'Using the URBANopt CLI to submit a Scenario optimization counts as one request per scenario'
              puts 'Using the URBANopt CLI to submit a Feature optimization counts as one request per feature'
              abort('Please wait and try again once the time period has elapsed.  The URBANopt CLI flag --reopt-keep-existing can be used to resume the optimization')
            elsif result.code == '404'
              @@logger.info("REOpt is still calculating. We'll give it a moment and check again")
              sleep 15
              tries += 1
              next
            elsif (result.code != '201') && (result.code != '200') # Anything in the 200s is success
              @@logger.warn("REopt has returned a '#{result.code}' status code. Visit https://developer.nrel.gov/docs/errors/ for more status code information")
              # display error messages
              json_res = JSON.parse(result.body, allow_nan: true)
              json_res['messages'].delete('warnings') if json_res['messages']['warnings']
              json_res['messages'].delete('Deprecations') if json_res['messages']['Deprecations']
              if json_res['messages']
                @@logger.error("MESSAGES: #{json_res['messages']}")
              end
            end
            tries = max_tries
          rescue StandardError => e
            @@logger.debug("error from REopt API: #{e}")
            if tries + 1 < max_tries
              @@logger.debug('trying again...')
            else
              @@logger.debug('max tries reached!')
              return result
            end
            tries += 1
          end
        end
        return result
      end

      ##
      # Checks if a optimization task can be submitted to the \REopt API
      ##
      #
      # [*parameters:*]
      #
      # * +data+ - _Hash_ - Default \REopt formatted post containing at least all the required parameters.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def check_connection(data)
        header = { 'Content-Type' => 'application/json' }
        http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
        if !@use_localhost
          http.use_ssl = true
        end

        post_request = Net::HTTP::Post.new(@uri_submit, header)
        post_request.body = ::JSON.generate(data, allow_nan: true)

        # Send the request
        response = make_request(http, post_request)

        if !response.is_a?(Net::HTTPSuccess)
          @@logger.error('Check_connection Failed')
          raise 'Check_connection Failed'
        end
        return true
      end

      ##
      # Completes a \REopt optimization. From a formatted hash, an optimization task is submitted to the API.
      # Results are polled at 5 second interval until they are ready or an error is returned from the API. Results
      # are written to disk.
      ##
      #
      # [*parameters:*]
      #
      # * +reopt_input+ - _Hash_ - \REopt formatted post containing at least required parameters.
      # * +filename+ - _String_ - Path to file that will be created containing the full \REopt response.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def resilience_request(run_uuid, filename)
        if File.directory? filename
          if run_uuid.nil?
            run_uuid = 'error'
          end
          if run_uuid.downcase.include? 'error'
            run_uuid = "error#{SecureRandom.uuid}"
          end
          filename = File.join(filename, "#{run_uuid}_resilience.json")
          @@logger.info("REopt results saved to #{filename}")
        end

        # Submit Job
        @@logger.info("Submitting Resilience Statistics job for #{run_uuid}")
        header = { 'Content-Type' => 'application/json' }
        http = Net::HTTP.new(@uri_submit_outagesimjob.host, @uri_submit_outagesimjob.port)
        if !@use_localhost
          http.use_ssl = true
        end
        post_request = Net::HTTP::Post.new(@uri_submit_outagesimjob, header)
        post_request.body = ::JSON.generate({ 'run_uuid' => run_uuid, 'bau' => false }, allow_nan: true)
        submit_response = make_request(http, post_request)
        @@logger.debug(submit_response.body)

        # Fetch Results
        uri = uri_resilience(run_uuid)
        http = Net::HTTP.new(uri.host, uri.port)
        if !@use_localhost
          http.use_ssl = true
        end

        # Wait a few seconds for the REopt database to update before GETing results
        sleep 5
        get_request = Net::HTTP::Get.new(uri.request_uri)
        response = make_request(http, get_request, 8)

        # Set a limit on retries when 404s are returned from REopt API
        elapsed_time = 0
        max_elapsed_time = 60 * 5

        # If database still hasn't updated, wait a little longer and try again
        while (elapsed_time < max_elapsed_time) && (response && response.code == '404')
          response = make_request(http, get_request)
          @@logger.warn('GET request was too fast for REOpt-API. Retrying...')
          elapsed_time += 5
          sleep 5
        end

        data = JSON.parse(response.body, allow_nan: true)
        text = JSON.pretty_generate(data)
        begin
          File.open(filename, 'w+') do |f|
            f.puts(text)
          end
        rescue StandardError => e
          @@logger.error("Cannot write - #{filename}")
          @@logger.error("ERROR: #{e}")
        end

        if response.code == '200'
          return data
        end

        @@logger.error("Error from REopt API - #{data['Error']}")
        return {}
      end

      ##
      # Completes a \REopt optimization. From a formatted hash, an optimization task is submitted to the API.
      # Results are polled at 5 second interval until they are ready or an error is returned from the API. Results
      # are written to disk.
      ##
      #
      # [*parameters:*]
      #
      # * +reopt_input+ - _Hash_ - \REopt formatted post containing at least required parameters.
      # * +filename+ - _String_ - Path to file that will be created containing the full \REopt response.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def reopt_request(reopt_input, filename)
        description = reopt_input[:Scenario][:description]

        @@logger.info("Submitting #{description} to REopt API")

        # Format the request
        header = { 'Content-Type' => 'application/json' }
        http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
        if !@use_localhost
          http.use_ssl = true
        end
        post_request = Net::HTTP::Post.new(@uri_submit, header)
        post_request.body = ::JSON.generate(reopt_input, allow_nan: true)

        # Send the request
        response = make_request(http, post_request)
        if !response.is_a?(Net::HTTPSuccess)
          @@logger.error('make_request Failed')
          raise 'Check_connection Failed'
        end

        # Get UUID
        run_uuid = JSON.parse(response.body, allow_nan: true)['run_uuid']

        if File.directory? filename
          if run_uuid.nil?
            run_uuid = 'error'
          end
          if run_uuid.downcase.include? 'error'
            run_uuid = "error#{SecureRandom.uuid}"
          end
          filename = File.join(filename, "#{description}_#{run_uuid}.json")
          @@logger.info("REopt results saved to #{filename}")
        end

        text = JSON.parse(response.body, allow_nan: true)
        if response.code != '201'
          File.open(filename, 'w+') do |f|
            f.puts(JSON.pretty_generate(text))
          end
          raise "Error in REopt optimization post - see #{filename}"
        end

        # Poll results until ready or error occurs
        status = 'Optimizing...'
        uri = uri_results(run_uuid)
        http = Net::HTTP.new(uri.host, uri.port)
        if !@use_localhost
          http.use_ssl = true
        end

        get_request = Net::HTTP::Get.new(uri.request_uri)

        while status == 'Optimizing...'
          response = make_request(http, get_request)

          data = JSON.parse(response.body, allow_nan: true)

          if data['outputs']['Scenario']['Site']['PV'].is_a?(Array)
            pv_sizes = 0
            data['outputs']['Scenario']['Site']['PV'].each do |x|
              pv_sizes += x['size_kw'].to_f
            end
          else
            pv_sizes = data['outputs']['Scenario']['Site']['PV']['size_kw'] || 0
          end
          sizes = pv_sizes + (data['outputs']['Scenario']['Site']['Storage']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0)
          status = data['outputs']['Scenario']['status']

          sleep 5
        end

        max_retry = 5
        tries = 0
        (check_complete = sizes == 0) && ((data['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] || 0) > 0)
        while (tries < max_retry) && check_complete
          sleep 3
          response = make_request(http, get_request)
          data = JSON.parse(response.body, allow_nan: true)
          if data['outputs']['Scenario']['Site']['PV'].is_a?(Array)
            pv_sizes = 0
            data['outputs']['Scenario']['Site']['PV'].each do |x|
              pv_sizes += x['size_kw'].to_f
            end
          else
            pv_sizes = data['outputs']['Scenario']['Site']['PV']['size_kw'] || 0
          end
          sizes = pv_sizes + (data['outputs']['Scenario']['Site']['Storage']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0)
          (check_complete = sizes == 0) && ((data['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] || 0) > 0)
          tries += 1
        end

        data = JSON.parse(response.body, allow_nan: true)
        text = JSON.pretty_generate(data)
        begin
          File.open(filename, 'w+') do |f|
            f.puts(text)
          end
        rescue StandardError
          @@logger.error("Cannot write - #{filename}")
        end

        if status == 'optimal'
          return data
        end

        error_message = data['messages']['error']
        raise "Error from REopt API - #{error_message}"
      end
    end
  end
end
