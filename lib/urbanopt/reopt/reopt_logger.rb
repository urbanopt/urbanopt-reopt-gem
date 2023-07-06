# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'logger'

module URBANopt
  module REopt
    @@reopt_logger = Logger.new($stdout)

    # Set Logger::DEBUG for development
    @@reopt_logger.level = Logger::WARN
    ##
    # Definining class variable "@@logger" to log errors, info and warning messages.
    def self.reopt_logger
      @@reopt_logger
    end
  end
end
