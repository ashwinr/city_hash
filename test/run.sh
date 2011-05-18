#!/bin/sh

# Compile the C version of city

make

# Test whether 'city' exists

if [ ! -f './city' ]
then
    echo "./city does not exist. Exiting..."
    exit -1
fi

# Run the comparison tests

ruby tc_rcity.rb

