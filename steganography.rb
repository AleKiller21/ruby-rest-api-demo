
'Class used for steganography. Its primary focus are bmp images'
class Steganography
    attr_reader :message_length_bits, :bitmap_data_start,
                :byte_length, :max_byte

    def initialize
        @message_length_bits = 16
        @bitmap_data_start = 54
        @byte_length = 8
        @max_byte = 128
    end

    def hide_message(image, message)
        message_bytes = message.unpack('C*')
        offset = set_message_length(message.length, image)
        count = 0

        (message_bytes).each do |letter|
            while count < byte_length
                bit = letter & (max_byte >> count)
                if bit == 0
                    offset = set_lsb(image, bit, offset)
                else
                    offset = set_lsb(image, 1, offset)
                end
                break if offset >= image.length
                count += 1
            end

            count = 0
            break if offset >= image.length
        end
    end

    def extract_message(image)
        size = get_message_length(image)
        offset = bitmap_data_start + message_length_bits
        message_data = Array.new(size, 0)

        (0...size).each do |i|
            buffer = Array.new(byte_length, 0)

            (0...byte_length).each do |counter|
                buffer[counter] = get_lsb(image[offset])
                offset += 1
                break if offset >= image.length
            end

            message_data[i] = make_byte(buffer)
            break if offset >= image.length
        end

        message_data
    end

    def get_message_length(image)
        offset = bitmap_data_start
        message_length_buffer = Array.new(message_length_bits, 0)

        (0...message_length_bits).each do |i|
            message_length_buffer[i] = get_lsb(image[offset])
            offset += 1
        end

        get_decimal_representation(message_length_buffer)
    end

    def get_decimal_representation(byte_buffer)
        size = pos = 0

        (byte_buffer).each do |byte|
            size += (1 << pos) if byte == 1
            pos += 1
        end

        size
    end

    def set_message_length(size, image)
        byte_buffer = get_binary_representation(size)
        offset = bitmap_data_start

        (byte_buffer).each do |byte|
            offset = set_lsb(image, byte, offset)
        end

        offset
    end

    def get_binary_representation(size)
        buffer = Array.new(message_length_bits, 0)
        remainder = size
        counter = 0

        while size >= 1
            remainder = size % 2
            size /= 2
            buffer[counter] = 1 if remainder != 0
            counter += 1
        end

        buffer
    end

    def set_lsb(image, target, offset)
        return offset + 1 if get_lsb(image[offset]) == target

        if target == 1 ? image[offset] += 1 : image[offset] -= 1
        end

        return offset + 1
    end

    def get_lsb(num)
        return 1 if num % 2 == 1
        return 0
    end

    def make_byte(byte_buffer)
        value = pos = 0
        i = byte_buffer.length - 1

        while i >= 0
            value += (1 << pos) if byte_buffer[i] == 1
            pos += 1
            i -= 1
        end

        value
    end

    private :set_message_length, :get_binary_representation, :set_lsb,
            :get_lsb
end
