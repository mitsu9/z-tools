require 'uri'
require "json"
require "net/http"

class ZendeskClient
  attr_reader :subdomain, :user, :token

  PER_PAGE = 100
  PER_QUERY = 1000
  PAGING_LIMIT = 10

  def initialize(subdomain, mail, access_token)
    @subdomain = subdomain
    @user      = "#{mail}/token"
    @token     = access_token
  end

  def fetch_tickets(begin_datetime, end_datetime)
    # begin_datetimeからend_datetimeまでのチケットを返す
    # チケットの数が多い場合日時を分割して取得する
    tickets = []
    count = count_tickets(begin_datetime, end_datetime)
    if count > PER_QUERY
        middle_datetime = get_middle_datetime(begin_datetime, end_datetime)
        tickets_l = fetch_tickets(begin_datetime, middle_datetime)
        tickets_r = fetch_tickets(middle_datetime, end_datetime)
        tickets = tickets + tickets_l + tickets_r
    else
      puts "fetch_tickets. begin_datetime: #{begin_datetime}, end_datetime: #{end_datetime}, count: #{count}"
      for page in 0..PAGING_LIMIT
        url = build_search_url(begin_datetime, end_datetime, page + 1)
        json = fetch_tickets_by_url(url)
        tickets = tickets + json['results']
        break if json['next_page'].nil?
      end
    end
    tickets
  end

  def count_tickets(begin_datetime, end_datetime)
    url = build_search_url(begin_datetime, end_datetime, 1)
    json = fetch_tickets_by_url(url)
    json["count"]
  end

  private

    def build_search_url(begin_datetime, end_datetime, page)
      query = "type:ticket created>=#{begin_datetime.strftime('%Y-%m-%dT%H:%M:%S')}+09:00 created<#{end_datetime.strftime('%Y-%m-%dT%H:%M:%S')}+09:00"
      encoded_query = URI.encode_www_form(query: query)
      "https://#{subdomain}.zendesk.com/api/v2/search.json?sort_by=created_at&per_page=#{PER_PAGE}&page=#{page}&#{encoded_query}"
    end

    def fetch_tickets_by_url(url)
      uri = URI url
      req = Net::HTTP::Get.new "#{uri.path}?#{uri.query}"
      req.basic_auth @user, @token
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request req }
      JSON.parse(response.body)
    end

    def get_middle_datetime(begin_datetime, end_datetime)
      begin_datetime + (end_datetime - begin_datetime)/2
    end
end
