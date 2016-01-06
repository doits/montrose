module Montrose
  class Options
    @default_starts = nil
    @default_ends = nil
    @default_every = nil

    MAX_HOURS_IN_DAY = 24
    MAX_DAYS_IN_YEAR = 366
    MAX_WEEKS_IN_YEAR = 53
    MAX_DAYS_IN_MONTH = 31

    class << self
      def new(options = {})
        return options if options.is_a?(self)
        super
      end

      def defined_options
        @defined_options ||= []
      end

      def def_option(name)
        defined_options << name.to_sym
        attr_accessor name
        protected :"#{name}="
      end

      attr_accessor :default_starts, :default_ends, :default_every

      # Return the default ending time.
      #
      # @example Recurrence.default_ends #=> <Date>
      #
      def default_ends
        case @default_ends
        when Proc
          @default_ends.call
        else
          @default_ends
        end
      end

      # Return the default starting time.
      #
      # @example Recurrence.default_starts #=> <Date>
      #
      def default_starts
        case @default_starts
        when Proc
          @default_starts.call
        when nil
          Time.now
        else
          @default_starts
        end
      end
    end

    def_option :every
    def_option :starts
    def_option :until
    def_option :hour
    def_option :day
    def_option :mday
    def_option :yday
    def_option :week
    def_option :month
    def_option :interval
    def_option :total

    def initialize(opts = {})
      defaults = {
        every: self.class.default_every,
        starts: self.class.default_starts,
        until: self.class.default_ends,
        day: nil,
        mday: nil,
        yday: nil,
        week: nil,
        month: nil,
        interval: 1,
        total: nil
      }

      options = defaults.merge(opts)
      options.each { |(k, v)| self[k] = v unless v.nil? }
    end

    def to_hash
      hash_pairs = self.class.defined_options.flat_map do |opt_name|
        [opt_name, send(opt_name)]
      end
      Hash[*hash_pairs].reject { |_k, v| v.nil? }
    end

    def []=(option, val)
      send(:"#{option}=", val)
    end

    def [](option)
      send(:"#{option}")
    end

    def merge(other)
      h1 = to_hash
      h2 = other.to_hash

      self.class.new(h1.merge(h2))
    end

    def fetch(key, default_val = nil, &block)
      instance_variable_get("@#{key}") || default_val || block.call
    end

    def every=(frequency)
      @every = Frequency.assert(frequency)
    end

    def hour=(hours)
      @hour = map_arg(hours) { |d| assert_range_includes(1..MAX_HOURS_IN_DAY, d) }
    end

    def day=(days)
      @day = map_arg(days) { |d| Montrose::Utils.day_number(d) }
    end

    def mday=(mdays)
      @mday = map_arg(mdays) { |d| assert_range_includes(1..MAX_DAYS_IN_MONTH, d, :absolute) }
    end

    def yday=(ydays)
      @yday = map_arg(ydays) { |d| assert_range_includes(1..MAX_DAYS_IN_YEAR, d, :absolute) }
    end

    def week=(weeks)
      @week = map_arg(weeks) { |d| assert_range_includes(1..MAX_WEEKS_IN_YEAR, d, :absolute) }
    end

    def month=(months)
      @month = map_arg(months) { |d| Montrose::Utils.month_number(d) }
    end

    def key?(key)
      respond_to?(key) && !send(key).nil?
    end

    private

    def map_arg(arg, &block)
      return nil unless arg

      array = case arg
              when Range
                arg.to_a
              else
                [*arg]
              end

      array.map(&block)
    end

    def assert_range_includes(range, item, absolute = false)
      test = absolute ? item.abs : item
      raise "Out of range" unless range.include?(test)

      item
    end
  end
end
