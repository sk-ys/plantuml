Redmine::Plugin.register :plantuml do
  name 'PlantUML plugin for Redmine'
  author 'Michael Skrynski'
  description 'This is a plugin for Redmine which renders PlantUML diagrams.'
  version '0.5.1'
  url 'https://github.com/dkd/plantuml'

  requires_redmine version: '2.6'..'6'

  settings(partial: 'settings/plantuml',
           default: {
            'plantuml_path' => {},
            'cache_seconds' => '0',
            'allow_includes' => false,
            'use_object_tag_for_svg' => true
          })

  Redmine::WikiFormatting::Macros.register do
    desc <<EOF
Render PlantUML image.
{{plantuml(png)
(Bob -> Alice : hello)
}}

Available options are:
** (png|svg)
EOF
    macro :plantuml do |obj, args, text|
      copy_old_setting
      raise 'No PlantUML path set.' if Setting.plugin_plantuml['plantuml_path'].blank?
      raise 'No or bad arguments.' if args.size != 1
      frmt = PlantumlHelper.check_format(args.first)
      image = PlantumlHelper.plantuml(text, args.first)

      if Regexp.compile("^http").match(image)
        if frmt[:type] == 'svg' && Setting.plugin_plantuml['use_object_tag_for_svg']
          content_tag(:object, '', data: image, type: 'image/svg+xml')
        else
          image_tag image
        end
      else
        image_tag "/plantuml/#{frmt[:type]}/#{image}#{frmt[:ext]}"
      end
    end


  end
end

Rails.configuration.to_prepare do
  # Guards against including the module multiple time (like in tests)
  # and registering multiple callbacks

  unless Redmine::WikiFormatting::Textile::Helper.included_modules.include? PlantumlHelperPatch
    Redmine::WikiFormatting::Textile::Helper.send(:include, PlantumlHelperPatch)
  end
  if (Redmine::VERSION::MAJOR == 3 && Redmine::VERSION::MINOR >= 1) || Redmine::VERSION::MAJOR >= 4
    unless Redmine::WikiFormatting::Markdown::Helper.included_modules.include? PlantumlHelperPatch
      Redmine::WikiFormatting::Markdown::Helper.send(:include, PlantumlHelperPatch)
    end
  end
end

private

def copy_old_setting
  if Setting.plugin_plantuml['plantuml_path'].blank?
    Setting.plugin_plantuml['plantuml_path'] = Setting.plugin_plantuml['plantuml_binary_default']
  end
end
