module PlantumlHelperPatch
  def self.included(base) # :nodoc:
    base.send(:prepend, HelperMethodsWikiExtensions)

    base.class_eval do
      # unloadable  # Remove for Redmine 6.0 or Rails 7, as unloadable is no longer supported.
      if Rails.version < '5.0.0'
        alias_method_chain :heads_for_wiki_formatter, :redmine_plantuml
      else
        alias_method :heads_for_wiki_formatter_without_redmine_plantuml, :heads_for_wiki_formatter
        alias_method :heads_for_wiki_formatter, :heads_for_wiki_formatter_with_redmine_plantuml
      end
    end
  end
end

module HelperMethodsWikiExtensions
  # extend the editor Toolbar for adding a plantuml button
  # overwrite this helper method to have full control about the load order
  def heads_for_wiki_formatter_with_redmine_plantuml
    heads_for_wiki_formatter_without_redmine_plantuml

    unless @heads_for_wiki_plantuml_included
      content_for :header_tags do
        if Redmine::VERSION::MAJOR >= 4
          javascript_include_tag('plantuml.js', plugin: 'plantuml') +
          stylesheet_link_tag('plantuml.css', plugin: 'plantuml')
        else
          javascript_include_tag('jstoolbar/jstoolbar-textile.min') +
          javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}") +
          stylesheet_link_tag('jstoolbar') +
          javascript_include_tag('plantuml.js', plugin: 'plantuml') +
          stylesheet_link_tag('plantuml.css', plugin: 'plantuml')
        end
      end
      @heads_for_wiki_plantuml_included = true
    end
  end
end

unless Redmine::WikiFormatting::Textile::Helper.included_modules.include? PlantumlHelperPatch
  Redmine::WikiFormatting::Textile::Helper.send(:include, PlantumlHelperPatch)
end

if (Redmine::VERSION::MAJOR == 3 && Redmine::VERSION::MINOR >= 1) || Redmine::VERSION::MAJOR >= 4
  if Redmine::VERSION::MAJOR < 6
    unless Redmine::WikiFormatting::Markdown::Helper.included_modules.include? PlantumlHelperPatch
      Redmine::WikiFormatting::Markdown::Helper.send(:include, PlantumlHelperPatch)
    end
  end
end

if Redmine::VERSION::MAJOR >= 5
  unless Redmine::WikiFormatting::CommonMark::Helper.included_modules.include? PlantumlHelperPatch
    Redmine::WikiFormatting::CommonMark::Helper.send(:include, PlantumlHelperPatch)
  end
end
