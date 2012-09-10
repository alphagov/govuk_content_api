object false

node :_response_info do
  { status: "ok" }
end

glue @local_authority do
  extends "_local_authority", object: @local_authority
end
