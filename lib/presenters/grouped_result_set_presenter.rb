class GroupedResultSetPresenter < ResultSetPresenter
  def present
    paginated_response_base.merge(
      "grouped_results" => grouped_results.map do |(group,formats), results|
        {
          "name" => group,
          "formats" => formats,
          "items" => results.map {|result|
            @result_presenter_class.new(result, @url_helper).present
          }
        }
      end
    )
  end

  private
  def grouped_results
    @result_set.results.group_by {|a|
      display_groups.detect {|group, formats| formats.include?(a.kind) }
    }.sort_by {|(name, formats), items|
      # force the order of groups as they're defined in the hash from the
      # display_groups method below
      display_groups.keys.index(name)
    }
  end

  def display_groups
    {
      "Services" => ["answer", "guide", "licence", "transaction"],
      "Statutory guidance" => ["statutory_guidance"],
      "Guidance" => ["guidance", "detailed_guide"],
      "Document collections" => ["document_collection"],
      "Forms" => ["form"],
      "Maps" => ["map"],
      "Statistics" => ["statistics", "statistical_data_set"],
      "Research and analysis" => ["research"],
      "Independent reports" => ["independent_report"],
      "Impact assessments" => ["impact_assessment"],
      "Policy papers" => ["policy_paper"],
      "Consultations" => ["consultation"],
      "Announcements" => [
        "transcript",
        "draft_text",
        "speaking_notes",
        "written_statement",
        "oral_statement",
        "authored_article",
        "news_story",
        "press_release",
        "government_response",
        "world_location_news_article"
      ]
    }
  end
end
