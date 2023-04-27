module Raven
  class SingleExceptionInterface < Interface
    attr_accessor :type, :value, :module, :stacktrace

    def to_hash(*args)
      data = super(*args)
      data[:stacktrace] = data[:stacktrace].to_hash if data[:stacktrace]
      data
    end
  end
end
