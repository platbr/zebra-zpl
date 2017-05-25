require "zebra/zpl/printable"

module Zebra
  module Zpl
    class Qrcode
      include Printable

      class InvalidScaleFactorError < StandardError; end
      class InvalidCorrectionLevelError < StandardError; end
      class InvalidZplVersionError < StandardError; end

      attr_writer :width
      attr_reader :width, :scale_factor, :correction_level, :zpl_version

      def scale_factor=(value)
        raise InvalidScaleFactorError unless (1..99).include?(value.to_i)
        @scale_factor = value
      end

      def correction_level=(value)
        raise InvalidCorrectionLevelError unless %w[L M Q H].include?(value.to_s)
        @correction_level = value
      end

      def zpl_version=(value)
        raise InvalidZplVersionError unless [1, 2].include?(value.to_i)
        @zpl_version = value
      end

      def to_zpl
        check_attributes
        return %(^FO#{x},#{y}^BQN,2,#{scale_factor},#{correction_level}^FD#{data}^FS) if @zpl_version == 1
        return %(^FO#{x},#{y}^BQN,2,#{scale_factor}^FD#{correction_level},A,#{data}^FS) if @zpl_version == 2
      end

      private

      def check_attributes
        super
        raise MissingAttributeError.new("the scale factor to be used is not given") unless @scale_factor
        raise MissingAttributeError.new("zpl version to be used is not given") unless @zpl_version
        raise MissingAttributeError.new("the error correction level to be used is not given") unless @correction_level
      end
    end
  end
end
