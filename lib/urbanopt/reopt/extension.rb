# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'openstudio/extension'

module URBANopt # :nodoc:
  module REopt # :nodoc:
    class Extension < OpenStudio::Extension::Extension # :nodoc:
      # Override parent class
      def initialize
        super

        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end
    end
  end
end
