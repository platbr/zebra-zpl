require "zebra/zpl/printable"
require 'labelary'

module Zebra
  module Zpl
    class Image
      include Printable

      attr_writer :width
      attr_writer :size, :file_path, :base64_image

      def to_zpl
        @data = Base64.decode64(@base64_image) if @base64_image
        @data = File.binread(@file_path) if @file_path
        check_attributes
        cache_img_file = File.join(Rails.root, 'tmp', "zebra_zpl_img_#{Digest::SHA1.hexdigest(@data)}_#{@size}")
        if File.exist?(cache_img_file) && !File.zero?(cache_img_file)
          prepared_img = File.binread(cache_img_file)
        else
          image = MiniMagick::Image.read(@data)
          image.flatten
          image.colorspace 'gray'
          image.monochrome
          image.resize(@size)
          image.extent "#{(image.width/8.0).round*8}x#{(image.height/8.0).round*8}"
          prepared_img = Labelary::Image.encode path: image.path, filename: 'image.png', mime_type: 'image/png'
        end
        %(^FO#{x},#{y},#{prepared_img})
      end

      private

      def check_attributes
        super
        # raise MissingAttributeError.new("file path to be used is not given") unless @file_path
        raise MissingAttributeError.new("size to be used is not given") unless @size
      end
    end
  end
end
