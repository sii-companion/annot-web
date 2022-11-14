SitemapGenerator::Sitemap.default_host = 'https://companion.gla.ac.uk'
SitemapGenerator::Sitemap.create do
  add faq_path, :priority => 0.7
  add survey2018_path, :priority => 0.7
  add examples_path, :priority => 0.7
  add getting_started_path, :priority => 0.7
end
