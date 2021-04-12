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
    settings_binary = Setting.plugin_plantuml['plantuml_binary_default']
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
    settings_binary = Setting.plugin_plantuml['plantuml_binary_default']
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
    frmt = check_format(args)
    name = construct_cache_key(sanitize_plantuml(text))
    text_encoded = encode(text)
    server_url = Setting.plugin_plantuml['plantuml_binary_default']

    url = URI.join(server_url, "/#{frmt[:type]}/#{text_encoded}").to_s
  end

  def self.sanitize_plantuml(text)
    return text if Setting.plugin_plantuml['allow_includes']
    text.gsub!(/!include.*$/, '')
    text
  end

  def self.encode(text)
    require 'plantuml-encode64'
    PlantUmlEncode64.new(sanitize_plantuml(text)).encode.to_s
  end
end
