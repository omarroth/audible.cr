require "crc32"
require "base64"
require "openssl/cipher"
require "openssl_ext"

module Audible
  class Client
    def sign_request(request)
      return Crypto.sign_request(request, @adp_token, @device_private_key)
    end
  end

  class Crypto
    def self.sign_request(request : HTTP::Request, adp_token, private_key)
      path = request.path
      query = request.query

      url = path
      if query
        url += "?#{query}"
      end

      sign_request(url, request.method, request.body, adp_token, private_key).each do |key, value|
        request.headers[key] = value
      end

      return request
    end

    def self.sign_request(url, method, body, adp_token, private_key, date = Time.utc.to_rfc3339)
      data = "#{method}\n#{url}\n#{date}\n"
      if body
        data += body.gets_to_end
        body.rewind
      end
      data += "\n"

      data += adp_token

      digest = OpenSSL::Digest.new("sha256")
      signed = Base64.strict_encode(private_key.sign(digest, data))
      signature = "#{signed}:#{date}"

      return {
        "x-adp-token"     => adp_token,
        "x-adp-alg"       => "SHA256withRSA:1.0",
        "x-adp-signature" => signature,
      }
    end

    def self.encrypt_metadata(metadata)
      checksum = Digest::CRC32.checksum(metadata).to_s(16).rjust(8, '0').upcase
      object = "#{checksum}##{metadata}"

      rounds = (object.size.to_f / 4).ceil.to_i

      temp2 = [] of UInt32
      rounds.times do |i|
        temp2 << (((object[i * 4]?.try &.ord || 0 & 255).to_u32) +
                  ((object[i * 4 + 1]?.try &.ord || 0 & 255).to_u32 << 8) +
                  ((object[i * 4 + 2]?.try &.ord || 0 & 255).to_u32 << 16) +
                  ((object[i * 4 + 3]?.try &.ord || 0 & 255).to_u32 << 24)).to_u32
      end

      wrap_constant = 2654435769
      constants = [1888420705, 2576816180, 2347232058, 874813317]

      minor_rounds = (6 + (52 / rounds)).floor
      first = temp2[0]
      last = temp2[rounds - 1]

      inner_roll = 0
      while minor_rounds > 0
        minor_rounds -= 1

        inner_roll &+= wrap_constant
        inner_variable = inner_roll >> 2 & 3

        rounds.times do |i|
          first = temp2[(i + 1) % rounds]
          last = temp2[i] &+=
            (last >> 5 ^ first << 2) &+ (first >> 3 ^ last << 4) ^
            (inner_roll ^ first) &+ (constants[i & 3 ^ inner_variable] ^ last)
        end
      end

      final_round = [] of String
      rounds.times do |i|
        slice = Slice.new(4, 0_u8)
        slice[0] = (temp2[i] & 255).to_u8
        slice[1] = (temp2[i] >> 8 & 255).to_u8
        slice[2] = (temp2[i] >> 16 & 255).to_u8
        slice[3] = (temp2[i] >> 24 & 255).to_u8
        final_round << String.new(slice)
      end

      final_round = final_round.join("")
      base64_encoded = Base64.strict_encode(final_round)
      final = "ECdITeCs:#{base64_encoded}"

      return final
    end

    def self.decrypt_metadata(metadata)
      metadata = URI.decode(metadata).lchop("ECdITeCs:")
      final_round = Base64.decode(metadata)

      temp2 = [] of UInt32
      final_round.each_slice(4).each do |chars|
        temp2 << (chars[0].to_u32!) +
                 (chars[1].to_u32! << 8) +
                 (chars[2].to_u32! << 16) +
                 (chars[3].to_u32! << 24)
      end

      rounds = temp2.size
      minor_rounds = (6 + (52 / rounds)).floor.to_i

      wrap_constant = 2654435769
      constants = [1888420705, 2576816180, 2347232058, 874813317]

      inner_roll = 0
      inner_variable = 0

      (minor_rounds + 1).times do
        inner_roll &+= wrap_constant
        inner_variable = inner_roll >> 2 & 3
      end

      while minor_rounds > 0
        minor_rounds -= 1

        inner_roll &-= wrap_constant
        inner_variable = inner_roll >> 2 & 3

        rounds.times do |i|
          i = rounds - i - 1

          first = temp2[(i + 1) % rounds]
          last = temp2[(i - 1) % rounds]

          last = temp2[i] &-=
            ((last >> 5 ^ first << 2) &+ (first >> 3 ^ last << 4) ^
             (inner_roll ^ first) &+ (constants[i & 3 ^ inner_variable] ^ last)).to_u32!
        end
      end

      object = [] of Char
      temp2.each do |block|
        {0, 8, 16, 24}.each do |align|
          if block.to_u32! >> align.to_u32! & 255 != 0
            object << (block.to_u32! >> align.to_u32! & 255).try &.chr
          end
        end
      end

      object = object.join("")
      return object[9..-1]
    end
  end
end
