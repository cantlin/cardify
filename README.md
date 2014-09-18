# cardify

This repository contains:

* a simple generator for embed codes
* an example implementation for the service that should provide the embeds themselves

## Generator

A minimal app that outputs iframes for third party embedding.

## Reference API

See the example directory. The API has two endpoints. Both accept any Guardian content path, e.g. ``media/greenslade/2014/sep/18/scottish-independence-national-newspapers``.

### /oembed/:path

Returns the structured data representation of the card, including OEmbed information.

The ``stub`` property contains the minimal HTML that's suitable for rendering by any naive client that hasn't implemented progressive enhancement.

````
{
	id: "gu-447511602",
	url: "http://www.theguardian.com/media/greenslade/2014/sep/18/scottish-independence-national-newspapers",
	title: "Scottish referendum - English newspapers publish dramatic front pages",
	published: "2014-09-18T09:38:00Z",
	trailText: "<p><strong>Roy Greenslade</strong> notes how editors have waved the flags in marking a historic day</p>",
	byline: "Roy Greenslade",
	type: "article",
	tone: "comment",
	byline_image: "http://static.guim.co.uk/sys-images/Guardian/Pix/pictures/2014/3/13/1394733747830/RoyGreenslade.png",
	stub: "<aside> <h3>Related article</h3> <a href="http://www.theguardian.com/media/greenslade/2014/sep/18/scottish-independence-national-newspapers" data-canonical-url="http://theguardian.com/embed/card/" data-default-height="300" data-interactive="http://interactive.guim.co.uk/embed/iframe-wrapper/0.1/boot.js">Scottish referendum - English newspapers publish dramatic front pages</a> </aside>"
}
````

### /html/:path

Returns the full HTML and CSS for the rendering of the card.

````

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
````

## Embedding the card

A Composer resolver has been configured to inject the stub HTML when presented with URLs like:

http://theguardian.com/embed/card/:path

External parties can simply point an iframe at the full HTML:

````
<iframe src="http://theguardian.com/embed/card/media/greenslade/2014/sep/18/scottish-independence-national-newspapers"></iframe>
````

## Upgrading the card

Progressive enhancement happens via the normal interactive route. [Enhancer](https://github.com/guardian/enhancer/blob/master/enhancer.js) calls the script referenced in the ``data-interactive`` property of the link, which replaced the link with an iframe pointing to the fully rendered version.