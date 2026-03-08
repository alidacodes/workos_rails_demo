module ApplicationHelper
  def flash_styling(type)
    case type
    when "notice"
      "bg-sky-200 text-sky-900"
    when "alert"
      "bg-red-100 text-red-700"
    else
      ""
    end
  end
end
