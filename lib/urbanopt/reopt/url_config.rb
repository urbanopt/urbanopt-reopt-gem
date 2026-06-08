# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'uri'

module URBANopt # :nodoc:
  module REopt  # :nodoc:
    ##
    # URLConfig provides centralized configuration for all REopt API endpoint URLs.
    # Supports environment variable overrides and default production URLs.
    #
    # Configuration priority:
    # 1. REOPT_BASE_URL environment variable
    # 2. Default production URL (developer.nlr.gov)
    ##
    class URLConfig
      ##
      # Default production base URL for REopt API
      DEFAULT_BASE_URL = 'https://developer.nlr.gov/api/reopt/v3'

      ##
      # Initialize URL configuration
      #
      # [*parameters:*]
      # * +api_key+ - _String_ - API key for endpoints that require authentication
      ##
      def initialize(api_key: nil)
        @api_key = api_key
        @base_url = determine_base_url
      end

      ##
      # Get the base URL for REopt API
      #
      # [*return:*] _String_ - Base URL without trailing slash
      ##
      def base_url
        @base_url
      end

      ##
      # Check if this URL requires an API key
      #
      # [*return:*] _Bool_ - True if API key is required
      ##
      def requires_api_key?
        @base_url.include?('developer.nlr.gov') || @base_url.include?('developer.nrel.gov')
      end

      ##
      # Get URI for job submission endpoint
      #
      # [*return:*] _URI_ - Complete URI for job submission
      ##
      def submit_uri
        url = "#{@base_url}/job"
        url += requires_api_key? ? "?api_key=#{@api_key}" : '/'
        URI.parse(url)
      end

      ##
      # Get URI for job results endpoint
      #
      # [*parameters:*]
      # * +run_uuid+ - _String_ - Unique identifier for the optimization job
      #
      # [*return:*] _URI_ - Complete URI for job results
      ##
      def results_uri(run_uuid)
        url = "#{@base_url}/job/#{run_uuid}/results"
        url += requires_api_key? ? "?api_key=#{@api_key}" : ''
        URI.parse(url)
      end

      ##
      # Get URI for resilience job submission endpoint
      #
      # [*return:*] _URI_ - Complete URI for ERP submission
      ##
      def erp_submit_uri
        url = "#{@base_url}/erp"
        url += requires_api_key? ? "?api_key=#{@api_key}" : '/'
        URI.parse(url)
      end

      ##
      # Get URI for resilience results endpoint
      #
      # [*parameters:*]
      # * +run_uuid+ - _String_ - Unique identifier for the resilience job
      #
      # [*return:*] _URI_ - Complete URI for resilience results
      ##
      def erp_results_uri(run_uuid)
        url = "#{@base_url}/erp/#{run_uuid}/results"
        url += requires_api_key? ? "?api_key=#{@api_key}" : ''
        URI.parse(url)
      end

      ##
      # Get URL string for any endpoint (used by GHP API)
      #
      # [*parameters:*]
      # * +endpoint+ - _String_ - Endpoint path (e.g., 'job', 'erp')
      # * +run_uuid+ - _String_ - Optional run UUID for results endpoints
      #
      # [*return:*] _String_ - Complete URL string
      ##
      def url_for(endpoint, run_uuid: nil)
        path = run_uuid ? "/#{endpoint}/#{run_uuid}/results" : "/#{endpoint}"
        url = "#{@base_url}#{path}"
        
        if requires_api_key?
          separator = path.include?('/results') ? '?' : (endpoint == 'erp' ? '?' : '?')
          url += "#{separator}api_key=#{@api_key}"
        end
        
        url
      end

      ##
      # Configure SSL settings for HTTP connection based on URL scheme
      #
      # [*parameters:*]
      # * +http+ - _Net::HTTP_ - HTTP connection object to configure
      ##
      def configure_ssl(http)
        if @base_url.start_with?('https')
          http.use_ssl = true
        end
      end

      private

      ##
      # Determine the appropriate base URL based on configuration priority
      #
      # [*return:*] _String_ - Selected base URL
      ##
      def determine_base_url
        # Priority 1: Environment variable override
        env_url = ENV['REOPT_BASE_URL']
        return env_url.chomp('/') if env_url && !env_url.strip.empty?

        # Priority 2: Default production URL
        DEFAULT_BASE_URL
      end
    end
  end
end