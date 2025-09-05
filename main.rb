require "./lib/google_serp_images"

file = ARGV.fetch(0) { abort "pass path to saved html" }
html = File.read(file)

result = extract(html)

puts result

File.write('output.json', result)