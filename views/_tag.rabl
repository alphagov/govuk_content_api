node(:id) { |t| tag_url(t) }
node(:web_url) { |t| tag_web_url(t) }
attribute :title

node :details do |tag|
  {
    description: tag.description,
    type: tag.tag_type
  }
end

child(:parent => :parent) do
  extends "_tag"
end