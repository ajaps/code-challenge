require "./lib/google_serp_images"

RSpec.describe "Google SERP Images" do
  let(:html) { File.read("./spec/fixtures/other-kind-of-carrousel.html") }
  let(:result) { JSON.parse(File.read("./spec/fixtures/other-kind-of-carrousel.json")) }
  let(:images_at_bottom_page_html) { File.read("./spec/fixtures/images-not-at-top-of-page.html") }
  let(:images_at_bottom_page_result) { JSON.parse(File.read("./spec/fixtures/images-not-at-top-of-page.json")) }
  let(:artwork_html) { File.read("./spec/fixtures/artist-artworks.html") }
  let(:artwork_result) { JSON.parse(File.read("./spec/fixtures/artist-artworks.json")) }

  it "extracts images data from Google SERP HTML" do
    expect(JSON.parse(extract(html))).to eq(result)
  end
  
  it "does not make http requests" do
    expect(Net::HTTP).not_to receive(:get)
    
    extract(html)
  end

  it "returns empty results when no images found" do
    empty_html = "<html><head><title>No Images</title></head><body><h1>No images here!</h1></body></html>"
    
    expect(JSON.parse(extract(empty_html))).to eq({ "images" => [] })
  end

  it "extracts artworks from Google SERPT HTML" do
    result = JSON.parse(extract(artwork_html))["artworks"]

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
    result = JSON.parse(extract(html))
    row = result["images"][0]

    expect(row["name"]).to eq("92,300+ Deep Ocean Fish Stock Photos, Pictures & Royalty ...")
    expect(row["extensions"]).to eq([])
  end

  it "extracts images for SERP HTML where the images section is not at the top" do
    result = JSON.parse(extract(images_at_bottom_page_html))
    row = result["images"][0]

    expect(row["name"]).to eq("Best Art Museums in the U.S.")
    expect(row["thumbnail"]).to be_a(Array)
    expect(row["link"]).to be_a(Array)
    expect(row["link"].first).to eq("https://www.fodors.com/news/photos/20-must-see-art-museums-in-america")

    expect(JSON.parse(extract(images_at_bottom_page_html))).to eq(images_at_bottom_page_result)
  end
end