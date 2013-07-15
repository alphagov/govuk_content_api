node do |artefact|
  return artefact.edition.nodes.map do |n|
    {
      :kind => n.kind,
      :slug => n.slug,
      :title => n.title,
      :body => process_content(n.body),
      :options => n.options.map { |o|
        {
          :label => o.label,
          :slug => o.slug,
          :next_node => o.next_node,
        }
      },
    }
  end
end
