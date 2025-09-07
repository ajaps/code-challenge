# frozen_string_literal: true

require "nokogiri"
require "json"

ABS = "https://www.google.com"

def extract(html)
  doc  = Nokogiri::HTML(html)

  results = []
  title = 'images'
  
  search_results = doc.css('div[data-attrid^="kc:/"][data-md]:not([role="presentation"])')[0]
  
  if search_results.nil?
    doc.xpath('//div[@jsname][.//img[@alt and starts-with(@src,"data:image")]]').each do |node|
      img_tag = node.at_css('img[alt]')
      a_tag = node.at_css("a")
      thumb = inline_thumb(img_tag)
      name = img_tag["alt"]&.strip

      next if a_tag.nil? || name.empty?

      results << row(name, nil, absolute(a_tag["href"]), thumb)
    end
  else
    title = carousel_title(search_results)

    search_results.css('a').each do |a|
      img = a.at_css('img[alt]')
      next unless img
      name = img["alt"]&.strip || a.text&.strip

      thumb = inline_thumb(img)
      date = extract_year(a)

      results << row(name, date, absolute(a["href"]), thumb)
    end
  end

  JSON.pretty_generate({ (title&.downcase || 'images') => results })
end

private

def carousel_title(node)
  anc = node.at_xpath(%q{
    ancestor::*[.//*[@role="heading" and @aria-level="2"]][1]
  })
  return anc&.at_xpath('.//*[@role="heading" and @aria-level="2"][1]')&.text&.strip&.downcase

  h2 = node.at_xpath('.//h2').text.strip.downcase
  return h2.text.strip.downcase if h2

  role_heading = node.at_xpath('.//*[@role="heading" and @aria-level="2"]')
  return role_heading.text.strip.downcase if role_heading

  nil
end

def row(name, date, link, thumb)
  { name: name, extensions: [date].compact, link: [link].compact, thumbnail: [thumb].compact }
end

def inline_thumb(img)
  s = img["src"]
  return s if s&.start_with?("data:image")
  ds = img["data-src"]
  return ds if ds&.start_with?("data:image")
  nil
end

def extract_year(anchor)
  anchor.xpath('.//text()[normalize-space()]').map(&:text)[-1]
end

def absolute(href)
  return nil if href.to_s.empty?
  href.start_with?("/") ? ABS + href : href
end