# All source comments are duplicated from Google's CityHash (1.0.2)
# implementation at: http://code.google.com/p/cityhash/

module CityHash

  def self.hash64(s, seed0 = nil, seed1 = nil)
    return CityHash::Internal.hash64(s) if seed0.nil?
    return CityHash::Internal.hash64WithSeed(s, seed0) if seed1.nil?
    return CityHash::Internal.hash64WithSeeds(s, seed0, seed1)
  end

  def self.hash128(s, seed = nil)
    return CityHash::Internal.hash128(s) if seed.nil?
    return CityHash::Internal.hash128WithSeed(s, seed)
  end

  module Internal

    # Some primes between 2^63 and 2^64 for various uses
    K0 = 0xc3a5c85c97cb3127
    K1 = 0xb492b66fbe98f273
    K2 = 0x9ae16a3b2f90404f
    K3 = 0xc949d7c7509e6557

    def self.lower32(x)
      x & 0xffffffff
    end

    def self.lower64(x)
      x & 0xffffffffffffffff
    end

    def self.higher64(x)
      x >> 64
    end

    # Return the hex-equivalent of byte-string
    def self.bytes(s)
      h = 0x0
      s.reverse.bytes do |b|
        h <<= 8
        h |= b
      end
      h
    end

    # Hash 128 input bits down to 64 bits of output.
    # This is intended to be a reasonably good hash function.
    def self.hash128To64(x)
      # Murmur-inspired hashing.
      kMul = 0x9ddfea08eb382d69
      a = lower64((lower64(x) ^ higher64(x)) * kMul)
      a ^= (a >> 47)
      b = lower64((higher64(x) ^ a) * kMul)
      b ^= (b >> 47)
      b = b * kMul
      lower64(b)
    end

    # Bitwise right rotate
    def self.rotate(val, shift)
      return val if shift == 0
      (val >> shift) | lower64((val << (64-shift)))
    end

    # Equivalent to rotate(...), but requires the second arg to be non-zero.
    def self.rotateByAtleast1(val, shift)
      (val >> shift) | lower64((val << (64-shift)))
    end

    def self.shiftMix(val)
      lower64(val ^ (val >> 47))
    end

    def self.hashLen16(u, v)
      uv = (v << 64) | u
      hash128To64(uv)
    end

    def self.hashLen0To16(s)
      len = s.length
      if len > 8
        a = bytes(s[0..7])
        b = bytes(s[-8..-1])
        return hashLen16(a, rotateByAtleast1(b+len, len)) ^ b
      elsif len >= 4
        a = bytes(s[0..3])
        return hashLen16(len + (a << 3), bytes(s[-4..-1]))
      elsif len > 0
        a = bytes(s[0])
        b = bytes(s[len >> 1])
        c = bytes(s[len-1])
        y = lower32(a + (b << 8))
        z = len + c*4
        return lower64(shiftMix(lower64(y * K2 ^ z * K3)) * K2)
      end
      K2
    end

    # This probably works well for 16-byte strings as well, but it may be overkill
    # in that case.
    def self.hashLen17To32(s)
      a = lower64(bytes(s[0..7]) * K1)
      b = bytes(s[8..15])
      c = lower64(bytes(s[-8..-1]) * K2)
      d = lower64(bytes(s[-16..-9]) * K0)
      hashLen16(lower64(rotate(lower64(a-b), 43) + rotate(c, 30) + d),
      lower64(a + rotate(b ^ K3, 20) - c) + s.length)
    end

    # Return a 16-byte hash for 48 bytes.  Quick and dirty.
    # Callers do best to use "random-looking" values for a and b.
    def self._weakHashLen32WithSeeds(w, x, y, z, a, b)
      a += w
      b = rotate(lower64(b+a+z), 21)
      c = a
      a += x
      a = lower64(a+y)
      b += rotate(a, 44)
      lower64(a+z) << 64 | lower64(b+c)
    end

    # Return a 16-byte hash for s[0] ... s[31], a, and b.  Quick and dirty.
    def self.weakHashLen32WithSeeds(s, a, b)
      _weakHashLen32WithSeeds(bytes(s[0..7]),
      bytes(s[8..15]),
      bytes(s[16..23]),
      bytes(s[24..31]),
      a,
      b)
    end

    # Return an 8-byte hash for 33 to 64 bytes.
    def self.hashLen33To64(s)
      len = s.length
      z = bytes(s[24..31])
      a = bytes(s[0..7]) + (len + bytes(s[-16..-9])) * K0
      a = lower64(a)
      b = rotate(lower64(a+z), 52)
      c = rotate(a, 37)
      a = lower64(a+bytes(s[8..15]))
      c = lower64(c+rotate(a, 7))
      a = lower64(a+bytes(s[16..23]))
      vf = lower64(a+z)
      vs = lower64(b + rotate(a, 31) + c)
      a = bytes(s[16..23]) + bytes(s[-32..-25])
      z = bytes(s[-8..-1])
      b = rotate(lower64(a+z), 52)
      c = rotate(a, 37)
      a = lower64(a+bytes(s[-24..-17]))
      c = lower64(c+rotate(a, 7))
      a = lower64(a+bytes(s[-16..-9]))
      wf = lower64(a+z)
      ws = lower64(b + rotate(a, 31) + c)
      r = shiftMix( lower64((vf + ws) * K2  + (wf + vs) * K0) )
      lower64( shiftMix(lower64(r*K0+vs)) * K2)
    end

    def self.hashLenAbove64(s)
      len = s.length
      # For strings over 64 bytes we hash the end first, and then as we
      # loop we keep 56 bytes of state: v, w, x, y, and z.
      x = bytes(s[0..7])
      y = bytes(s[-16..-9]) ^ K1
      z = bytes(s[-56..-49]) ^ K0
      v = weakHashLen32WithSeeds(s[-64..-1], len, y)
      w = weakHashLen32WithSeeds(s[-32..-1], lower64(len*K1), K0)

      z = lower64(z + shiftMix(lower64(v)) * K1)
      x = lower64(rotate(lower64(z+x), 39) * K1)
      y = lower64(rotate(y, 33) * K1)

      # Decrease len to the nearest multiple of 64, and operate on 64-byte chunks.
      len = (len - 1) & ~63;
      begin
        xrv = lower64(x + y + higher64(v) + bytes(s[16..23]))
        yrv = lower64(y + lower64(v) + bytes(s[48..55]))
        x = lower64(rotate(xrv, 37) * K1)
        y = lower64(rotate(yrv, 42) * K1)
        x ^= lower64(w)
        y ^= higher64(v)
        z = rotate(z ^ higher64(w), 33)
        v = weakHashLen32WithSeeds(s, lower64(lower64(v) * K1), lower64(x + higher64(w)))
        w = weakHashLen32WithSeeds(s[32..-1], lower64(z + lower64(w)), y)
        z, x = x, z
        s = s[64..-1]
        len -= 64
      end while len != 0

      hashLen16(lower64(hashLen16(higher64(v), higher64(w)) + shiftMix(y) * K1 + z),
      lower64(hashLen16(lower64(v), lower64(w)) + x))
    end

    # A subroutine for CityHash128().  Returns a decent 128-bit hash for strings
    # of any length representable in ssize_t.  Based on City and Murmur.
    def self.cityMurmur(s, seed)
      len = s.length
      a = lower64(seed)
      b = higher64(seed)
      c,d = 0, 0
      l = s.length - 16
      if l <=0 then
        a = lower64(shiftMix(lower64(a * K1)) * K1)
        c = lower64(b*K1 + hashLen0To16(s))
        d = shiftMix(lower64(a + (len >=8 ? bytes(s[0..7]) : c)))
      else
        c = hashLen16(lower64(bytes(s[-8..-1]) + K1), a)
        d = hashLen16(lower64(b+len), lower64(c + bytes(s[-16..-9])))
        a = lower64(a+d)
        begin
          a ^= lower64(shiftMix(lower64(bytes(s[0..7]) * K1)) * K1)
          a = lower64(a*K1)
          b ^= a
          c ^= lower64(shiftMix(lower64(bytes(s[8..15]) * K1)) * K1)
          c = lower64(c*K1)
          d ^= c
          s = s[16..-1]
          l -= 16
        end while l > 0
      end
      a = hashLen16(a, c)
      b = hashLen16(d, b)
      ((a^b) << 64) | hashLen16(b, a)
    end

    def self.hash128WithSeed(s, seed)
      # Create a copy of the input string
      orig_s = String.new(s)
      len = s.length
      return cityMurmur(s, seed) if len < 128

      # We expect len >= 128 to be the common case.  Keep 56 bytes of state:
      # v, w, x, y, and z.
      x = lower64(seed)
      y = higher64(seed)
      z = lower64(len * K1)
      vf = lower64(lower64(rotate(y ^ K1, 49) * K1) + bytes(s[0..7]))
      vs = lower64(lower64(rotate(vf, 42) * K1) + bytes(s[8..15]))
      wf = lower64(lower64(rotate(lower64(y+z), 35) * K1) + x)
      ws = lower64(rotate(lower64(x + bytes(s[88..95])), 53) * K1)
      v = (vf << 64) | vs
      w = (wf << 64) | ws

      # This is the same inner loop as CityHash64(), manually unrolled.
      begin
        x = lower64(rotate(lower64(x + y + vf + bytes(s[16..23])), 37) * K1)
        y = lower64(rotate(lower64(y + vs + bytes(s[48..55])), 42) * K1)
        x ^= ws
        y ^= vf
        z = rotate(z ^ wf, 33)
        v = weakHashLen32WithSeeds(s, lower64(vs * K1), lower64(x+wf))
        w = weakHashLen32WithSeeds(s[32..-1], lower64(z+ws), y)
        vf, vs = higher64(v), lower64(v)
        wf, ws = higher64(w), lower64(w)
        z,x = x,z
        s = s[64..-1]

        x = lower64(rotate(lower64(x + y + vf + bytes(s[16..23])), 37) * K1)
        y = lower64(rotate(lower64(y + vs + bytes(s[48..55])), 42) * K1)
        x ^= ws
        y ^= vf
        z = rotate(z ^ wf, 33)
        v = weakHashLen32WithSeeds(s, lower64(vs * K1), lower64(x+wf))
        w = weakHashLen32WithSeeds(s[32..-1], lower64(z+ws), y)
        vf, vs = higher64(v), lower64(v)
        wf, ws = higher64(w), lower64(w)
        z,x = x,z
        s = s[64..-1]
        len -= 128
      end while len >= 128

      y = lower64(y + rotate(wf, 37) * K0 + z)
      x = lower64(x + rotate(lower64(vf + z), 49) * K0)
      # If 0 < len < 128, hash up to 4 chunks of 32 bytes each from the end of s.
      tail_done = 0
      while tail_done < len do
        tail_done += 32
        y = lower64(rotate(lower64(y-x), 42) * K0 + vs)
        wf = lower64(wf + bytes(orig_s[16-tail_done..23-tail_done]))
        x = lower64(rotate(x, 49) * K0 + wf)
        wf = lower64(wf + vf)
        v = weakHashLen32WithSeeds(orig_s[-tail_done..-1], vf, vs)
        vf, vs = higher64(v), lower64(v)
      end
      # At this point our 48 bytes of state should contain more than
      # enough information for a strong 128-bit hash.  We use two
      # different 48-byte-to-8-byte hashes to get a 16-byte final result.
      x = hashLen16(x, vf)
      y = hashLen16(y, wf)
      hf = lower64(hashLen16(lower64(x + vs), ws) + y)
      hs = lower64(hashLen16(lower64(x + ws), lower64(y + vs)))
      (hf << 64) | hs
    end

    # Internal interface routines for CityHash module
    def self.hash64(s)
      len = s.length
      if len <= 16
        return hashLen0To16(s)
      elsif len <= 32
        return hashLen17To32(s)
      elsif len <= 64
        return hashLen33To64(s)
      else
        return hashLenAbove64(s)
      end      
    end

    def self.hash64WithSeed(s, seed)
      hash64WithSeeds(s, K2, seed)
    end

    def self.hash64WithSeeds(s, seed0, seed1)
      hashLen16(lower64(hash64(s) - seed0), seed1)
    end

    def self.hash128(s)
      len = s.length
      if len >=16
        seed = ((bytes(s[8..15]) << 64) | (bytes(s[0..7]) ^ K3))
        return hash128WithSeed(s[16..-1], seed)
      elsif len >= 8
        seed = (bytes(s[-8..-1]) ^ K1) << 64
        seed |= (bytes(s[0..7]) ^ lower64(len*K0))
        return hash128WithSeed("", seed)
      else
        return hash128WithSeed(s, (K1<<64) | K0)
      end
    end

  end # Module Internal
end # Module CityHash
