# encoding: utf-8

module Zebra
  module Zpl
    class Label
      class InvalidPrintSpeedError     < StandardError; end
      class InvalidPrintDensityError   < StandardError; end
      class PrintSpeedNotInformedError < StandardError; end
      class InvalidZplVersionError < StandardError; end

      attr_writer :copies
      attr_reader :elements, :tempfile
      attr_accessor :width, :length, :gap, :print_speed, :print_density, :zpl_version

      def initialize(options = {})
        @zpl_version = options[:zpl_version] || 1
        options.each_pair { |key, value| self.__send__("#{key}=", value) if self.respond_to?("#{key}=") }
        @elements = []
      end

      def length_and_gap=(length_and_gap)
        self.length = length_and_gap[0]
        self.gap    = length_and_gap[1]
      end

      def print_speed=(s)
        raise InvalidPrintSpeedError unless (0..6).include?(s)
        @print_speed = s
      end

      def print_density=(d)
        raise InvalidPrintDensityError unless (0..6).include?(d)
        @print_density = d
      end

      def zpl_version=(value)
        raise InvalidZplVersionError unless [1, 2].include?(value.to_i)
        @zpl_version = value
      end

      def copies
        @copies || 1
      end

      def <<(element)
        element.width = self.width
        element.zpl_version = self.zpl_version if element.respond_to?(:zpl_version)
        elements << element
      end

      def dump_contents(io = STDOUT)
        io << to_zpl
      end

      def to_zpl
        check_required_configurations
        io = ''
        io << "^SZ#{zpl_version}"
        # Start format
        io << "^XA"
        # ^LL<label height in dots>,<space between labels in dots>
        # io << "^LL#{length},#{gap}\n" if length && gap
        io << "^LL#{length}" if length
        # ^LH<label home - x,y coordinates of top left label>
        io << "^LH0,0"
        # ^LS<shift the label to the left(or right)>
        io << "^LS10"
        # ^PW<label width in dots>
        io << "^PW#{width}" if width
        # Print Rate(speed) (^PR command)
        io << "^PR#{print_speed}"
        # Density (D command) "Carried over from EPL, does this exist in ZPL ????"
        # io << "D#{print_density}\n" if print_density

        # TEST ZPL (comment everything else out)...
        # io << "^XA^WD*:*.FNT*^XZ"
        # TEST ZPL SEGMENT
        # io << "^WD*:*.FNT*"
        # TEST AND GET CONFIGS
        # io << "^HH"

        elements.each do |element|
          io << element.to_zpl
        end
        # Specify how many copies to print
        io << "^PQ#{copies}"
        # End format
        io << "^XZ"
      end

      def persist
        # debugger
        tempfile = Tempfile.new "zebra_label"
        dump_contents tempfile
        tempfile.close
        @tempfile = tempfile
        tempfile
      end

      def persisted?
        !!self.tempfile
      end

      private

      def check_required_configurations
        raise PrintSpeedNotInformedError unless print_speed
      end
    end
  end
end
