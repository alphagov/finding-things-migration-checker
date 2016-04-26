#!/usr/bin/env ruby

# Extracts content items with their links from the publishing API database
# (about 200,000 items) and dumps the data to disk as CSV.

require 'pg'
require 'csv'

if ARGV.length < 1
  $stderr.puts "Usage: #{$0} output_file"
  exit 1
end

connection = PG.connect(ENV["DATABASE_URL"] || 'postgresql:///publishing_api_development')

query = <<-QUERY
SELECT
  content.content_id,
  locations.base_path,
  content.publishing_app,
  links.link_type,
  array_agg(links.target_content_id) as link_content_ids,
  array_agg(link_locations.base_path) as link_base_paths
FROM
  content_items content
  join states on states.content_item_id = content.id and states.name='published'
  join locations on locations.content_item_id = content.id
  join link_sets on link_sets.content_id = content.content_id
  join links on links.link_set_id = link_sets.id

  -- Find the live location for each link
  join content_items link_content on links.target_content_id = link_content.content_id
  join states link_states on link_states.content_item_id = link_content.id and link_states.name='published'
  join locations link_locations on link_locations.content_item_id = link_content.id

  group by content.content_id, locations.base_path, content.publishing_app, links.link_type
  order by content.publishing_app, content.content_id, links.link_type
QUERY

CSV.open(ARGV.first, 'wb') do |csv|
  results = connection.exec(query)
  puts "#{results.ntuples} rows found"

  results.each_row do |row|
    csv << row
  end
end
