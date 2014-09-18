# cardify

This repository contains:

* a simple generator for embed codes
* example implementation for the service that should actually provide the embeds

## generator

See [/generator](https://github.com/cantlin/cardify/tree/master/generator). Barebones app that outputs iframes for third party embedding.

```
cd generator
gem install sinatra yaml json curb
cp example_conf.yaml conf.yaml
ruby generator.rb
```

## example API

See [/example](https://github.com/cantlin/cardify/tree/master/example). The API has two endpoints. Both accept any Guardian content path, e.g. ``media/greenslade/2014/sep/18/scottish-independence-national-newspapers``.

```
cd example
gem install sinatra yaml json curb dalli
apt-get install memcached
cp example_conf.yaml conf.yaml
ruby api.rb
```

### /oembed/:path

Returns the structured data representation of the card, including OEmbed information.

The ``stub`` property contains the minimal HTML that's suitable for rendering by any naive client that hasn't implemented progressive enhancement.

```javascript
{
	provider_name: "The Guardian",
	provider_url: "http://www.theguardian.com/",
	version: "1.0",
	type: "link",
	url: "http://www.theguardian.com/media/greenslade/2014/sep/18/scottish-independence-national-newspapers",
	title: "Scottish referendum - English newspapers publish dramatic front pages",
	published: "2014-09-18T09:38:00Z",
	trailText: "<p><strong>Roy Greenslade</strong> notes how editors have waved the flags in marking a historic day</p>",
	byline: "Roy Greenslade",
	tone: "comment",
	content_type: "article",
	byline_image: "http://static.guim.co.uk/sys-images/Guardian/Pix/pictures/2014/3/13/1394733747830/RoyGreenslade.png",
	author_name: "Roy Greenslade",
	author_url: "http://www.theguardian.com/profile/roygreenslade",
	stub: "<aside> <h3>Related article</h3> <a href="http://www.theguardian.com/media/greenslade/2014/sep/18/scottish-independence-national-newspapers" data-canonical-url="http://theguardian.com/embed/card/" data-default-height="300" data-interactive="http://interactive.guim.co.uk/embed/iframe-wrapper/0.1/boot.js">Scottish referendum - English newspapers publish dramatic front pages</a> </aside>"
}
```

### /html/:path

Returns the full HTML and CSS for the rendering of the card.

```html
<a href="http://www.theguardian.com/media/greenslade/2014/sep/18/scottish-independence-national-newspapers" data-gu-card>
	<aside class="gu-card-container comment has-byline-image">
		<h2>Scottish referendum - English newspapers publish dramatic front pages</h2>
		
			<p class="byline">Roy Greenslade</p>
		
		<p class="trailtext"><strong>Roy Greenslade</strong> notes how editors have waved the flags in marking a historic day</p>
		
			<img class="byline-image" src="http://static.guim.co.uk/sys-images/Guardian/Pix/pictures/2014/3/13/1394733747830/RoyGreenslade.png">
		
	</aside>
</a>
<link rel="stylesheet" href="/card.css" />
<link rel="stylesheet" href="/bower_components/guss-webfonts/nextgen-webfonts.css" />
```

## Embedding the card

External parties can simply point an iframe at the full HTML:

```html
<iframe frameborder="0" seamless width="416" height="250" src="http://cantl.in:8080/html/media/greenslade/2014/sep/18/scottish-independence-national-newspapers"></iframe>
```

Guardian staff will be able to paste URLs into Composer of this type:

```
http://theguardian.com/embed/card/:path
```

## Upgrading the card

Progressive enhancement on theguardian.com happens via the normal route we use for interactive components, i.e. via [boot.js](http://interactive.guim.co.uk/embed/iframe-wrapper/0.1/boot.js). [Enhancer](https://github.com/guardian/enhancer/blob/master/enhancer.js) calls the script referenced in the ``data-interactive`` property of the link, which replaces the link with an iframe pointing to the fully rendered version.

## TODO

* Replace the direct iframe embed for third parties with a script similar to boot.js
