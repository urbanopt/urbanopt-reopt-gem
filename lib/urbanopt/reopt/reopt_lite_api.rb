# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

require 'net/https'
require 'openssl'
require 'uri'
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
      # \REoptLiteAPI manages submitting optimization tasks to the \REopt Lite API  and recieving results.
      # Results can either be sourced from the production \REopt Lite API with an API key from developer.nrel.gov, or from
      # a version running at localhost.
      ##
      #
      # [*parameters:*]
      #
      # * +use_localhost+ - _Bool_ - If this is true, requests will be sent to a version of the \REopt Lite API running on localhost. Default is false, such that the production version of \REopt Lite is accessed.
      # * +nrel_developer_key+ - _String_ - API key used to access the \REopt Lite APi. Required only if localhost is false. Obtain from https://developer.nrel.gov/signup/
      ##
      def initialize(nrel_developer_key = nil, use_localhost = false)
        @use_localhost = use_localhost
        if @use_localhost
          @uri_submit = URI.parse('http//:127.0.0.1:8000/v1/job/')
          @uri_submit_outagesimjob = URI.parse('http//:127.0.0.1:8000/v1/outagesimjob/')
        else
          if [nil, '', '<insert your key here>'].include? nrel_developer_key
            if [nil, '', '<insert your key here>'].include? DEVELOPER_NREL_KEY
              raise 'A developer.nrel.gov API key is required. Please see https://developer.nrel.gov/signup/ then update the file urbanopt-reopt-gem/developer_nrel_key.rb'
            else
              nrel_developer_key = DEVELOPER_NREL_KEY
            end
          end
          @nrel_developer_key = nrel_developer_key
          @uri_submit = URI.parse("https://developer.nrel.gov/api/reopt/v1/job/?api_key=#{@nrel_developer_key}")
          @uri_submit_outagesimjob = URI.parse("https://developer.nrel.gov/api/reopt/v1/outagesimjob/?api_key=#{@nrel_developer_key}")
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
      # * +run_uuid+ - _String_ - Unique run_uuid obtained from the \REopt Lite job submittal URL for a specific optimization task.
      #
      # [*return:*] _URI_ - Returns URI object for use in calling the \REopt Lite results endpoint for a specifc optimization task.
      ##
      def uri_results(run_uuid) # :nodoc:
        if @use_localhost
          return URI.parse("http://127.0.0.1:8000/v1/job/#{run_uuid}/results")
        end
        return URI.parse("https://developer.nrel.gov/api/reopt/v1/job/#{run_uuid}/results?api_key=#{@nrel_developer_key}")
      end

      ##
      # URL of the resilience statistics end point for a specific optimization task
      ##
      #
      # [*parameters:*]
      #
      # * +run_uuid+ - _String_ - Resilience statistics for a unique run_uuid obtained from the \REopt Lite job submittal URL for a specific optimization task.
      #
      # [*return:*] _URI_ - Returns URI object for use in calling the \REopt Lite resilience statistics endpoint for a specifc optimization task.
      ##
      def uri_resilience(run_uuid) # :nodoc:
        if @use_localhost
          return URI.parse("http://127.0.0.1:8000/v1/job/#{run_uuid}/resilience_stats")
        end
        return URI.parse("https://developer.nrel.gov/api/reopt/v1/job/#{run_uuid}/resilience_stats?api_key=#{@nrel_developer_key}")
      end

      def make_request(http, r, max_tries = 3)
        result = nil
        tries = 0
        while tries < max_tries
          begin
               result = http.request(r)
               tries = 4
             rescue StandardError
               tries += 1
             end
        end
        return result
      end

      ##
      # Checks if a optimization task can be submitted to the \REopt Lite API
      ##
      #
      # [*parameters:*]
      #
      # * +data+ - _Hash_ - Default \REopt Lite formatted post containing at least all the required parameters.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def check_connection(data)
        header = { 'Content-Type' => 'application/json' }
        http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
        if !@use_localhost
          http.use_ssl = true
        end

        request = Net::HTTP::Post.new(@uri_submit, header)
        request.body = ::JSON.generate(data, allow_nan: true)

        # Send the request
        response = make_request(http, request)

        if !response.is_a?(Net::HTTPSuccess)
          @@logger.error('Check_connection Failed')
          raise 'Check_connection Failed'
        end
        return true
      end

      ##
      # Completes a \REopt Lite optimization. From a formatted hash, an optimization task is submitted to the API.
      # Results are polled at 5 second interval until they are ready or an error is returned from the API. Results
      # are written to disk.
      ##
      #
      # [*parameters:*]
      #
      # * +reopt_input+ - _Hash_ - \REopt Lite formatted post containing at least required parameters.
      # * +filename+ - _String_ - Path to file that will be created containing the full \REopt Lite response.
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
        
        #Submit Job
        @@logger.info("Submitting Resilience Statistics job for #{run_uuid}")
        header = { 'Content-Type' => 'application/json' }
        http = Net::HTTP.new(@uri_submit_outagesimjob.host, @uri_submit_outagesimjob.port)
        if !@use_localhost
          http.use_ssl = true
        end
        request = Net::HTTP::Post.new(@uri_submit_outagesimjob, header)
        request.body = ::JSON.generate({"run_uuid" => run_uuid, "bau" => false }, allow_nan: true)
        submit_response = make_request(http, request)
        @@logger.info(submit_response.body)

        #Fetch Results
        uri = uri_resilience(run_uuid)
        http = Net::HTTP.new(uri.host, uri.port)
        if !@use_localhost
          http.use_ssl = true
        end

        elapsed_time = 0
        max_elapsed_time = 60
        
        request = Net::HTTP::Get.new(uri.request_uri)
        response = make_request(http, request)
        
        while (elapsed_time < max_elapsed_time) & (response.code == "404")
          response = make_request(http, request)
          elapsed_time += 5 
          sleep 5

        end
        
        data = JSON.parse(response.body)
      
        File.open(filename, 'w+') do |f|
          f.write(::JSON.generate(data, allow_nan: true))
        end

        if response.code == "200"
          return data
        end

        raise "Error from REopt API - #{data['Error']}"
      end

      ##
      # Completes a \REopt Lite optimization. From a formatted hash, an optimization task is submitted to the API.
      # Results are polled at 5 second interval until they are ready or an error is returned from the API. Results
      # are written to disk.
      ##
      #
      # [*parameters:*]
      #
      # * +reopt_input+ - _Hash_ - \REopt Lite formatted post containing at least required parameters.
      # * +filename+ - _String_ - Path to file that will be created containing the full \REopt Lite response.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def reopt_request(reopt_input, filename)
        description = reopt_input[:Scenario][:description]

        @@logger.info("Submitting #{description} to REopt Lite API")

        # Format the request
        header = { 'Content-Type' => 'application/json' }
        http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
        if !@use_localhost
          http.use_ssl = true
        end
        request = Net::HTTP::Post.new(@uri_submit, header)
        request.body = ::JSON.generate(reopt_input, allow_nan: true)

        # Send the request
        response = make_request(http, request)

        # Get UUID
        run_uuid = JSON.parse(response.body, allow_nan:true)['run_uuid']

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

        if response.code != '201'
          File.open(filename, 'w+') do |f|
            f.write(::JSON.generate(response.body, allow_nan: true))
          end
          puts(response.body)
          raise "Error in REopt optimization post - see #{filename}"
        end

        # Poll results until ready or error occurs
        status = 'Optimizing...'
        uri = uri_results(run_uuid)
        http = Net::HTTP.new(uri.host, uri.port)
        if !@use_localhost
          http.use_ssl = true
        end

        request = Net::HTTP::Get.new(uri.request_uri)

        while status == 'Optimizing...'
          response = make_request(http, request)
          
          data = JSON.parse(response.body, allow_nan:true)

          if data['outputs']['Scenario']['Site']['PV'].kind_of?(Array)
            pv_sizes = 0
            data['outputs']['Scenario']['Site']['PV'].each do |x|
              pv_sizes = pv_sizes + x['size_kw'].to_f
            end 
          else
            pv_sizes = data['outputs']['Scenario']['Site']['PV']['size_kw'] || 0
          end
          sizes = pv_sizes + (data['outputs']['Scenario']['Site']['Storage']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0)
          status = data['outputs']['Scenario']['status']

          sleep 5
        end

        _max_retry = 5
        _tries = 0
        (check_complete = sizes == 0) && ((data['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] || 0) > 0)
        while (_tries < _max_retry) && check_complete
          sleep 1
          response = make_request(http, request)
          data = JSON.parse(response.body, allow_nan:true)
          if data['outputs']['Scenario']['Site']['PV'].kind_of?(Array)
            pv_sizes = 0
            data['outputs']['Scenario']['Site']['PV'].each do |x|
              pv_sizes = pv_sizes + x['size_kw'].to_f
            end 
          else
            pv_sizes = data['outputs']['Scenario']['Site']['PV']['size_kw'] || 0
          end
          sizes = pv_sizes + (data['outputs']['Scenario']['Site']['Storage']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) + (data['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0)
          (check_complete = sizes == 0) && ((data['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] || 0) > 0)
          _tries += 1
        end

        begin
          File.open(filename, 'w+') do |f|
            f.write(::JSON.generate(data, allow_nan: true))
          end
        rescue
          puts("Error saving results to #{filename}")
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
