require 'test_helper'

class TagRequestTest < GovUkContentApiTest
  should "load list of tags" do
    Tag.expects(:all).returns([
      Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag'),
      Tag.new(tag_id: 'better-tag', tag_type: 'Audience', description: 'Lots to say', name: 'better tag'),
    ])
    get "/tags.json"
    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)["status"]
    assert_equal 2, JSON.parse(last_response.body)['results'].count
  end

  should "filter all tags by type" do
    Tag.expects(:where).with(tag_type: 'Section').returns([
      Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag'),
    ])
    get "/tags.json?type=Section"
    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)["status"]
    assert_equal 1, JSON.parse(last_response.body)['results'].count
  end

  should "load a specific tag" do
    fake_tag = Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag')
    Tag.expects(:where).with(tag_id: 'good-tag').returns([fake_tag])
    get '/tags/good-tag.json'
    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)["status"]
    assert_equal 'Lots to say for myself', JSON.parse(last_response.body)['result']['fields']['description']
  end

  should "return 404 if specific tag not found" do
    Tag.expects(:where).with(tag_id: 'bad-tag').returns([])
    get '/tags/bad-tag.json'
    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["status"]
  end
end
