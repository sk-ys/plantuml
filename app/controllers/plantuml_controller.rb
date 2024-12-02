class PlantumlController < ApplicationController
  # unloadable  # Remove for Redmine 6.0 or Rails 7, as unloadable is no longer supported.

  def convert
    frmt = PlantumlHelper.check_format(params[:content_type])
    filename = params[:filename]
    send_file(PlantumlHelper.plantuml_file(filename, frmt[:ext]), type: frmt[:content_type], disposition: frmt[:inline])
  end
end
