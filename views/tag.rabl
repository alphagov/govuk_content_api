object false

node :_response_info do
  { status: "ok" }
end

glue @tag do
  extends "_tag", object: @tag
end
