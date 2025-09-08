# frozen_string_literal: true

require "nokogiri"
require "json"

ABS = "https://www.google.com"

def extract(html)
  doc  = Nokogiri::HTML(html)

  results = []
  title = 'not-found'
  
  container = doc.at_css('div[data-attrid^="kc:/"][data-md]:not([role="presentation"])')

  # carousels with data attribute starting with "kc:/"
  if container
    title = carousel_title(container) # get title of the carousel section

    container.css('a').each do |a|
      img = a.at_css('img[alt]')
      next unless img
      name = extract_name(a)

      thumb = inline_thumb(img)
      date = extract_year(a)

      results << row(name, date, absolute(a["href"]), thumb)
    end
  end
  
  JSON.pretty_generate({ title&.downcase => results })
end

private

def carousel_title(node)
  anc = node.at_xpath(%q{ancestor::*[.//*[@role="heading"]][1]})
  anc&.at_xpath('.//*[@role="heading"][1]')&.text&.strip&.downcase
end

def row(name, date, link, thumb)
  { name: name, extensions: [date].compact, link: [link].compact, thumbnail: [thumb].compact }
end

def inline_thumb(img)
  img["src"] if img["src"]&.start_with?("data:image/")
end

def extract_name(anchor)
  anchor.xpath('.//text()[normalize-space()]')[0].text
end

def extract_year(anchor)
  expected_date_field = anchor.xpath('.//text()[normalize-space()]')[-1].text
  expected_date_field[/\b\d{4}\b/]
end

def absolute(href)
  return nil if href.to_s.empty?
  href.start_with?("/") ? ABS + href : href
end