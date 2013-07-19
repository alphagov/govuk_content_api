@artefact.live_related_artefacts.each do |key, artefacts|
  child(artefacts => key.to_sym) do
    extends "_basic_artefact"
  end
end
