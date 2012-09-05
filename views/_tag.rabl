node(:id) { |t| tag_url(t) }
node(:web_url) { nil }
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

node(:content_with_tag) do |tag|
  {
    id: with_tag_url(tag),
    web_url: with_tag_web_url(tag)
  }
end