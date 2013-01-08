package h2d;
import flash.display.BitmapData;

class Font extends Tile {

	static var DEFAULT_CHARS = " ?!\"#$%&|<>@'()[]{}*+-=/.,:;0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzéèêëÉÈÊËàâäáÀÂÄÁùûüúÙÛÜÚîïíÎÏÍôóöõÔÓÖæÆœŒçÇñÑ¡¿ß";

	public var glyphs : Array<Tile>;
	public var lineHeight : Int;
	
	public function new()
	{
		super(null, 0, 0, 0, 0);	
	}
	
	public static function fromAutoTile( image : BitmapData, width : Int, height : Int, ?chars )
	{
		var self = new Font();
		if( chars == null )
			chars = DEFAULT_CHARS;
		var auto = Tile.autoTile(image, width, height);
		
		var flat = new Array();
		for (y in 0...auto.tiles.length)
		{
			for (x in 0...auto.tiles[y].length)
				flat.push(auto.tiles[y][x]);
		}
		
		self.glyphs = new Array();
		for (i in 0...chars.length)
		{
			self.glyphs[chars.charCodeAt(i)] = flat[i];
		}
		
		self.setTexture(auto.main.getTexture());
		for( t in flat )
			t.setTexture(self.innerTex);
		
		return self;
	}
	
	public static function fromEmbedded( name : String, size : Int, aa = true, ?chars )
	{
		var self = new Font();
		if( chars == null )
			chars = DEFAULT_CHARS;
		var tf = new flash.text.TextField();
		var fmt = tf.defaultTextFormat;
		fmt.font = name;
		fmt.size = size;
		fmt.color = 0xFFFFFF;
		tf.defaultTextFormat = fmt;
		for( f in flash.text.Font.enumerateFonts() )
			if( f.fontName == name ) {
				tf.embedFonts = true;
				break;
			}
		if( !aa ) {
			tf.sharpness = 400;
			tf.gridFitType = flash.text.GridFitType.PIXEL;
			tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		}
		var surf = 0;
		var sizes = [];
		for( i in 0...chars.length ) {
			tf.text = chars.charAt(i);
			var w = Math.ceil(tf.textWidth);
			if( w == 0 ) continue;
			var h = Math.ceil(tf.textHeight);
			surf += (w + 1) * (h + 1);
			if( h > self.lineHeight )
				self.lineHeight = h;
			sizes[i] = { w:w, h:h };
		}
		var side = Math.ceil( Math.sqrt(surf) );
		var width = 1;
		while( side > width )
			width <<= 1;
		var height = width;
		while( width * height >> 1 > surf )
			height >>= 1;
		var all, bmp;
		do {
			bmp = new flash.display.BitmapData(width, height, true, 0);
			self.glyphs = [];
			all = [];
			var m = new flash.geom.Matrix();
			var x = 0, y = 0, lineH = 0;
			for( i in 0...chars.length ) {
				var size = sizes[i];
				if( size == null ) continue;
				var w = size.w;
				var h = size.h;
				if( x + w > width ) {
					x = 0;
					y += lineH + 1;
				}
				// no space, resize
				if( y + h > height ) {
					bmp.dispose();
					bmp = null;
					height <<= 1;
					break;
				}
				m.tx = x - 2;
				m.ty = y - 2;
				tf.text = chars.charAt(i);
				bmp.draw(tf, m);
				var t = self.sub(x, y, w, h);
				all.push(t);
				self.glyphs[chars.charCodeAt(i)] = t;
				// next element
				if( h > lineH ) lineH = h;
				x += w + 1;
			}
		} while( bmp == null );
		self.setTexture(Tile.fromBitmap(bmp).getTexture());
		for( t in all )
			t.setTexture(self.innerTex);	
		return self;
	}
	
}