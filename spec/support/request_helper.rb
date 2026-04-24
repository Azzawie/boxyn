module RequestHelper
  def json
    JSON.parse(response.body)
  end

  def json_ids
    json.map { |r| r['id'] }
  end
end
