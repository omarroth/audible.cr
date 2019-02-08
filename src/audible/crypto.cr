require "crc32"
require "base64"

def encrypt(metadata)
  checksum = CRC32.checksum(metadata).to_s(16).rjust(8, '0').upcase
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

    inner_roll += wrap_constant
    inner_variable = inner_roll >> 2 & 3

    rounds.times do |i|
      first = temp2[(i + 1) % rounds]
      last = temp2[i] +=
        (last >> 5 ^ first << 2) + (first >> 3 ^ last << 4) ^
        (inner_roll ^ first) + (constants[i & 3 ^ inner_variable] ^ last)
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
