require 'digest/sha2'
require 'uri'

module PlantumlHelper
  ALLOWED_FORMATS = {
    'png' => { type: 'png', ext: '.png', content_type: 'image/png', inline: true },
    'svg' => { type: 'svg', ext: '.svg', content_type: 'image/svg+xml', inline: true }
  }.freeze

  def self.construct_cache_key(key)
    ['plantuml', Digest::SHA256.hexdigest(key.to_s)].join('_')
  end

  def self.check_format(frmt)
    ALLOWED_FORMATS.fetch(frmt, ALLOWED_FORMATS['png'])
  end

  def self.plantuml_file(name, extension)
    File.join(Rails.root, 'files', "#{name}#{extension}")
  end

  def self.plantuml(text, args)
    settings_binary = Setting.plugin_plantuml['plantuml_path']
    if Regexp.compile("^http").match(settings_binary)
      name = plantuml_server(text, args)
    else
      name = plantuml_local(text, args)
    end
    name
  end

  def self.plantuml_local(text, args)
    frmt = check_format(args)
    name = construct_cache_key(sanitize_plantuml(text))
    settings_binary = Setting.plugin_plantuml['plantuml_path']
    unless File.file?(plantuml_file(name, '.pu'))
      File.open(plantuml_file(name, '.pu'), 'w') do |file|
        file.write "@startuml\n"
        file.write sanitize_plantuml(text) + "\n"
        file.write '@enduml'
      end
    end
    unless File.file?(plantuml_file(name, frmt[:ext]))
      `"#{settings_binary}" -charset UTF-8 -t"#{frmt[:type]}" "#{plantuml_file(name, '.pu')}"`
    end
    name
  end

  def self.plantuml_server(text, args)
    server_url = Setting.plugin_plantuml['plantuml_path']
    server_url << '/' if !server_url.end_with?('/')
    frmt = check_format(args)
    name = construct_cache_key(sanitize_plantuml(text))
    text_encoded = encode64(text)

    # If using HUFFMAN encoding, need to add ~1 to the header.
    url = URI.join(server_url, "#{frmt[:type]}/~1#{text_encoded}").to_s
  end

  def self.sanitize_plantuml(text)
    return text if Setting.plugin_plantuml['allow_includes']
    text.gsub!(/!include.*$/, '')
    text
  end

  # ref. https://plantuml.com/code-javascript-synchronous
  def self.encode64(text)
    compressed = Zlib::Deflate.deflate(text, Zlib::BEST_COMPRESSION)
    compressed.chars.each_slice(3).map do |chars|
      append3bytes(chars[0].ord, chars[1]&.ord.to_i, chars[2]&.ord.to_i)
    end.join
  end

  def self.encode6bit(b)
    if (b < 10) 
        return (48 + b).chr
    end
    b -= 10
    if (b < 26) 
        return (65 + b).chr
    end
    b -= 26
    if (b < 26) 
        return (97 + b).chr
    end
    b -= 26
    if (b == 0) 
        return '-'
    elsif (b == 1) 
        return '_'
    end
    return '?'
  end

  def self.append3bytes(b1, b2, b3)
    [
      b1 >> 2,
      ((b1 & 0x3) << 4) | (b2 >> 4),
      ((b2 & 0xF) << 2) | (b3 >> 6),
      b3 & 0x3F,
    ].map { |c| self.encode6bit(c & 0x3F) }.join
  end
end
