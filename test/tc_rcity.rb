#!/usr/local/bin/ruby

require 'city_hash'
require 'test/unit'
require 'zip/zip'

=begin
  Run a gamut of test strings against both Google's C++ and
  our Ruby implementation, and verify the results.
  The test verifies both 64 and 128-bit hashes with and without
  random seeds for strings of length from 1 to 2K.
  The strings are sourced in randomly from 'Crime and Punishment'
  obtained from Project Gutenberg.
=end

class TestCityHash < Test::Unit::TestCase
  def initialize(testFunction)
    super testFunction
    puts 'Unzipping contents of test.zip'
    @files = []
    Zip::ZipFile::open('./test.zip') do |zf|
      zf.each { |file|
        fpath = File.join('/tmp', file.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zf.extract(file, fpath) unless File.exist?(fpath)
        @files.push(File.new(fpath)) if fpath =~ /txt$/
      }
    end
  end

  def getRandomString(file, len)
    size = file.size
    begin
      offset = rand(size)
    end while offset+len >= size
    file.pos = offset
    file.read(len)
  end

  def getHash(function, seed1, seed2, s)
    hash = -1
    case function
    when 1
      hash = CityHash.hash64(s)
    when 2
      hash = CityHash.hash64(s, seed1)
    when 3
      hash = CityHash.hash64(s, seed1, seed2)
    when 4
      hash = CityHash.hash128(s)
    else
      hash = CityHash.hash128(s, (seed2 << 64) | seed1)
    end
    hash
  end

  def test_city_hash
    max_int_64 = 2**64-1
    puts 'Running tests'
    start = Time.now
    ffile = File.new('failures.txt', 'w')
    for i in 1..2048 # length of hash string
      for j in 1..2 # number of iterations
        for k in 1..5 # all hash functions
          seed1 = rand(max_int_64)
          seed2 = rand(max_int_64)
          file = @files[0] # only a single test file
          string = getRandomString(file, i)
          # Remove any unicode characters
          string.gsub!(/[\x80-\xff]/,"")
          # Escape a couple of shell characters (anything else missing?)
          cstring = string.gsub("\"", "\\\"")
          cstring = cstring.gsub("$", "\\$")
          # Calculate Google's C++ hash
          cityArgs = "#{k} "
          if(k == 1 || k == 4)
            cityArgs += "\"#{cstring}\""
          elsif (k == 2)
            cityArgs += "#{seed1} \"#{cstring}\""
          else
            cityArgs += "#{seed1} #{seed2} \"#{cstring}\""
          end
          cHex = `./city #{cityArgs}`
          cHex = cHex.hex
          # Calculate our Ruby hash
          rHex = getHash(k, seed1, seed2, string)
          # Verify hashes
          ffile.puts "Failed hash function #{k} for string \"#{string}\" with hashes #{cHex} and #{rHex}" if(cHex != rHex)
          assert(cHex == rHex)
        end
      end
    end
    elapsed = (Time.now - start)/60.0
  end

end
