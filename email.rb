
require 'pqueue'

  'Provides functionality to sort all the emails from a given file'
  class Item
    attr_accessor :value, :segment, :consumed, :file

    def initialize(value, segment, consumed, file)
      @value = value
      @segment = segment
      @consumed = consumed
      @file = file
    end
  end

  class Sort
    attr_reader :chunk_size, :output_buffer, :input_buffer, :reg_ex, :filename, :output_file

    def initialize(filename, output_file_name)
      @chunk_size = 20
      @output_buffer = 50
      @input_buffer = 20
      @reg_ex = /[a-z0-9.]+@[a-z0-9-]+([.][a-z]+)+/
      @filename = filename
      @output_file = output_file_name
    end

    def sort
      files_written = construct_sub_files
      merge(files_written)
    end

    def construct_sub_files
      counter = 0
      files_written = 0
      chunk = []
      file = File.new(filename)

      while true
        line = file.gets
        break unless line

        chunk.push(line.downcase)
        counter += 1

        next if counter != chunk_size

        process_lines(chunk, files_written)
        counter = 0
        chunk.clear
        files_written += 1
      end

      if counter > 0
        process_lines(chunk, files_written)
        files_written += 1
      end

      files_written
    end

    def merge(files_written)
      heap = []

      build_min_heap(files_written, heap)
      heap = PQueue.new(heap) { |a, b| a.value < b.value }
      write_sorted_mail_output(heap)
    end

    def process_lines(chunk, fileswritten)
      add_new_line(chunk)
      write_to_chunk(chunk, fileswritten)
    end

    def add_new_line(chunk)
      email = chunk[chunk.length - 1]
      chunk[chunk.length - 1] = email + "\n" if email[email.length - 1] != "\n"
    end

    def write_to_chunk(chunk, files_written)
      filename = "temp#{files_written}.txt"
      filter(chunk)
      chunk = chunk.sort

      return unless chunk.length

      sub_file = File.new(filename, 'w')
      sub_file.puts(chunk)
      sub_file.close
    end

    def filter(chunk)
      chunk.delete_if { |email| !reg_ex.match(email) }
    end

    def build_min_heap(files_written, heap)
      (0...files_written).each do |counter|
        filename = "temp#{counter}.txt"
        file = File.new(filename)
        emails = read_temp_file(file)
        consumed = input_buffer
        value = emails[0]
        item = Item.new(value, emails, consumed, file)
        heap.push(item)
      end
    end

    def read_temp_file(file)
      buffer = []

      (0...input_buffer).each do |counter|
        line = file.gets
        break unless line
        buffer.push(line)
      end

      buffer
    end

    def write_sorted_mail_output(heap)
      output = []
      output_file = File.new(self.output_file, 'w')

      while heap.size > 0
        email = get_email(heap)
        if output.length >= output_buffer
          output_file.puts(output)
          output.clear
        end
        output.push(email)
      end

      output_file.puts(output) if output.length > 0

      output_file.close
    end

    def get_email(heap)
      item = heap.top
      email = item.value
      item.segment.delete(email)

      if item.segment.empty?
        item.segment = read_temp_file(item.file)
        if item.segment.empty?
          item.file.close
          heap.pop
          return email
        end
      end

      item.value = item.segment[0]
      heap.swap(item)
      email
    end

    private :construct_sub_files, :add_new_line, :build_min_heap,
            :read_temp_file, :get_email
  end
