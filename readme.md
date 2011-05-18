# CityHash for Ruby

This is an implementation of Google's CityHash for Ruby. It supports both 64-bit and 128-bit hashes. The newer CityHashCrc routines have not yet been implemented. Please note that the code has not been optimized for speed.

## Installing CityHash

Installing CityHash is as simple as

	gem install CityHash

## Using CityHash

	require 'CityHash'

	# Calculate a 64-bit hash
	CityHash.hash64('New York City')
	
	# Calculate a 64-bit hash with seed
	CityHash.hash64('East Village', 0xef23)
	
	# Calculate a 64-bit hash with two seeds
	CityHash.hash64('Meatpacking', 0xba3c, 0x5acd)
	
	# Calculate a 128-bit hash
	CityHash.hash128('SoHo')
	
	# Calculate a 128-bit hash with seed
	CityHash.hash128('Upper West Side', 0x8ad1)

## Testing CityHash

The test functions generate random strings and compare the outputs of both the C and Ruby implementations. The source for these strings is Dostoevsky's 'Crime and Punishment', obtained from Project Gutenberg and compressed within test.zip.

### Prerequisites

Google's implementation of Cityhash must be installed on the test system, since the test routines link against libcityhash.

This 'city_hash' gem must already be installed on the test system.

### Running the tests

	cd test/
	./run.sh

### Authors

	Ashwin Ramaswamy

### Copyright

Copyright (c) 2011 ashwinr. Please see license.txt for further details.
