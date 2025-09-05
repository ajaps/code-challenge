# frozen_string_literal: true

require "nokogiri"
require "json"

ABS = "https://www.google.com"

def extract(html)
  doc  = Nokogiri::HTML(html)

  results = []

  # title = doc.at_xpath('//div[@id="rcnt"]//*[@role="heading" and not(@data-attrid)]')&.text&.strip
  # title = doc.at_css("title")&.text&.strip if title.nil? || title.empty?
  title = ""

  doc.css('div[data-attrid*="visual_artist:works"] a').each do |a|
    img = a.at_css('img[alt]')
    next unless img
    name = img["alt"]&.strip
    next if name.nil? || name.empty?

    thumb = inline_thumb(img)
    date = extract_year(a)

    results << row(name, date, absolute(a["href"]), thumb)
  end

  if results.empty?
    title = "images"
    doc.xpath('//div[@jsname][.//img[@alt and starts-with(@src,"data:image")]]').each do |node|
      img_tag = node.at_css('img[alt]')
      a_tag = node.at_css("a")
      thumb = inline_thumb(img_tag)
      name = img_tag["alt"]&.strip

      next if a_tag.nil? || name.empty?

      results << row(name, nil, absolute(a_tag["href"]), thumb)
    end
  else
    title = "artworks"
  end

  JSON.pretty_generate({ (title&.downcase || 'images') => results })
end

private

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