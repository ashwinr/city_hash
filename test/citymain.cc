#include <iostream>
#include <string>
#include <sstream>
#include <iomanip>
#include "city.h"

void usage(char** argv)
{
  std::cout << "Usage: " << argv[0] << " <hash function> <seed1> <seed2> <hash string>" << std::endl;
  std::cout << "hashfunction = 1, for CityHash64" << std::endl;
  std::cout << "             = 2, for CityHash64WithSeed" << std::endl;
  std::cout << "             = 3, for CityHash64WithSeeds" << std::endl;
  std::cout << "             = 4, for CityHash128" << std::endl;
  std::cout << "             = 5, for CityHash128WithSeed" << std::endl;
  exit(-1);
}

int main(int argc, char** argv)
{
  if(argc < 3)
    {
      usage(argv);
    }

  std::stringstream hss, ss1, ss2;
  int hashFunction = -1;
  uint64 seed1, seed2;
  uint128 seed128;
  std::string hashString;
  hss << argv[1], hss >> hashFunction;
  switch(hashFunction)
    {
    case 1:
    case 4:
      hashString = argv[2];
      break;

    case 2:
      if(argc != 4)
	usage(argv);
      ss1 << argv[2], ss1 >> seed1;
      hashString = argv[3];
      break;

    case 3:
    case 5:
      if(argc != 5)
	usage(argv);
      ss1 << argv[2], ss1 >> seed1;
      ss2 << argv[3], ss2 >> seed2;
      hashString = argv[4];
      break;
    }

  uint64 hash64;
  uint128 hash128;
  switch(hashFunction)
    {
    case 1:
      hash64 = CityHash64(hashString.c_str(),
			  hashString.length());
      break;
		
    case 2:
      hash64 = CityHash64WithSeed(hashString.c_str(),
				  hashString.length(), seed1);
      break;
			
    case 3:
      hash64 = CityHash64WithSeeds(hashString.c_str(),
				   hashString.length(),
				   seed1, seed2);
      break;
			
    case 4:
      hash128 = CityHash128(hashString.c_str(), hashString.length());
      break;
			
    case 5:
      seed128 = uint128(seed1, seed2);
      hash128 = CityHash128WithSeed(hashString.c_str(),
				    hashString.length(), seed128);
      break;
    }

  if(hashFunction <= 3)
    {
      std::cout << "0x" << std::hex << hash64 << std::endl;
    }
  else
    {
      std::cout << "0x" << std::hex << hash128.first << std::setfill('0')
		<< std::setw(16) << hash128.second << std::endl;
    }

  return 0;
}
