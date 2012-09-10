object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Local Authorities" }
node(:total) { @local_authorities.count }
node(:results) do
  @local_authorities.map { |authority|
    partial "_local_authority", object: authority
  }
end
