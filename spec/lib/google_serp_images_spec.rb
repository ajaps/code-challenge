require "./lib/google_serp_images"

RSpec.describe "Google SERP Images" do
  let(:artwork_html) { File.read("./spec/fixtures/artist-artworks.html") }
  let(:artwork_result) { JSON.parse(File.read("./spec/fixtures/artist-artworks.json")) }
  let(:rihanna_albums_html) { File.read("./spec/fixtures/rihanna-albums.html") }
  let(:rihanna_albums_json) { JSON.parse(File.read("./spec/fixtures/rihanna-albums.json")) }
  
  it "does not make http requests" do
    expect(Net::HTTP).not_to receive(:get)
    
    extract(artwork_html)
  end

  it "returns empty results when no images found" do
    empty_html = "<html><head><title>No Images</title></head><body><h1>No images here!</h1></body></html>"
    
    expect(JSON.parse(extract(empty_html))).to eq({ "not-found" => [] })
  end

  it "extracts artworks from Google SERPT HTML" do
    expect(JSON.parse(extract(artwork_html))).to eq(artwork_result)
  end

  it "extracts name, extensions array (date), and absolute Google link" do
    html = <<~HTML
      <div id="rcnt"><div role="heading">Vincent van Gogh</div></div>
      <div data-attrid="kc:/visual_art/visual_artist:works">
        <div class="iELo6">
          <a href="/search?sca_esv=c2e426814f4d07e9&q=The+Starry+Night">
            <img alt="The Starry Night" src="data:image/gif;base64,R0lGODlhAQABAIAAAP///////yH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==">
            <div class="KHK6lb">
              <div class="pgNMRc">The Starry Night</div>
              <div class="cxzHyb">1889</div>
            </div>
          </a>
        </div>
      </div>
    HTML

    result = JSON.parse(extract(artwork_html))
    row = result["artworks"][0]

    expect(row["name"]).to eq("The Starry Night")
    expect(row["extensions"]).to eq(["1889"])
    expect(row["link"]).to be_a(Array)
    expect(row["link"].first).to start_with("https://www.google.com/search?")
  end

  it "returns 'extensions' as empty array if no date found" do
    result = JSON.parse(extract(artwork_html))
    row = result["artworks"][10]

    expect(row["name"]).to eq("Sunflowers")
    expect(row["extensions"]).to eq([])
  end

  it "uses the carousel title as the key in the output JSON" do
    result = JSON.parse(extract(artwork_html))

    expect(result.keys.first).to eq("artworks")
  end

  it "extracts Rihanna albums from Google SERP HTML" do
    expect(JSON.parse(extract(rihanna_albums_html))).to eq(rihanna_albums_json)
  end
  it "extracts name, extensions array (date), and absolute Google link for Rihanna albums" do
    result = JSON.parse(extract(rihanna_albums_html))
    row = result["albums"][0]

    expect(row["name"]).to eq("Anti")
    expect(row["extensions"]).to eq(["2016"])
    expect(row["link"]).to be_a(Array)
    expect(row["link"].first).to start_with("https://www.google.com/search?")
  end
end