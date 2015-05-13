# Disable paperclip logging
Paperclip.options[:log] = false
Paperclip.options[:use_exif_orientation] = false



module Paperclip
  class ExtraFileAdapter
    def initialize(target)
      @target = target
      @tempfile = @target[:tempfile]
    end
    def original_filename; @target[:filename]; end
    def content_type; @target[:type]; end
    def fingerprint; @fingerprint ||= Digest::MD5.file(path).to_s; end
    def size; File.size(path); end
    def nil?; false; end
    def read(length = nil, buffer = nil); @tempfile.read(length, buffer); end
    def rewind; @tempfile.rewind; end # We don't use this directly, but aws/sdk does.
    def close; @tempfile.close; end
    def closed?; @tempfile.closed?; end
    def eof?; @tempfile.eof?; end
    def path; @tempfile.path; end
  end

  module Interpolations
    def rails_root(attachment, style_name); APP_ROOT; end
    def rails_env(attachment, style_name); APP_ENV; end
  end
end