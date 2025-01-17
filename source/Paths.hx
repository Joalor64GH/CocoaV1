package;

import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.system.System;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import sys.io.File;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;
import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

	public static var customImagesLoaded:Map<String, FlxGraphic> = new Map();
	public static var customSoundsLoaded:Map<String, Sound> = new Map();

	static var garbageAssets:Array<String> = [];

	public static var ignoreFolders:Array<String> = [
		'songs',
		'characters',
		'images',
		'custom_events',
		'custom_notetypes',
		'stages',
		'videos',
		'weeks',
		'scripts',
	];

	public static var modFolders:Array<String> = [];

	public static function checkModFolders():Void
	{
		var path:Array<String> = FileSystem.readDirectory(FileSystem.absolutePath(mods('')));

		if (path != null)
			for (i in path)
				if (!ignoreFolders.contains(i))
					modFolders.push(i);
	}

	public static function clearMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj:FlxGraphic = FlxG.bitmap._cache.get(key);
			if (obj != null && !customImagesLoaded.exists(key))
			{
				OpenFlAssets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		garbageAssets = [];
		OpenFlAssets.cache.clear("songs");
	}

	public static function clearTrashMemory()
	{
		for (key in customImagesLoaded.keys())
		{
			if (!garbageAssets.contains(key))
			{
				var obj:FlxGraphic = customImagesLoaded.get(key);

				@:privateAccess
				if (obj != null)
				{
					OpenFlAssets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					customImagesLoaded.remove(key);
				}
			}
		}

		System.gc();
	}

	public static function getPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function txt(key:String)
	{
		return getPath('songs/$key.txt');
	}

	inline static public function xml(key:String)
	{
		return getPath('songs/$key.xml');
	}

	inline static public function json(key:String)
	{
		return getPath('songs/$key.json');
	}

	inline static public function lua(key:String)
	{
		return getPath('$key.lua');
	}

	static public function video(key:String)
	{
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
		{
			return file;
		}

		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?returnString:Bool = false):Dynamic
	{
		var file:String = modsSounds(key);

		if (!FileSystem.exists(file))
			file = getPath('sounds/$key.$SOUND_EXT');

		if (!customSoundsLoaded.exists(file))
			customSoundsLoaded.set(file, Sound.fromFile(file));

		return if (returnString) file else customSoundsLoaded.get(file);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int):Sound
	{
		return sound(key + FlxG.random.int(min, max));
	}

	inline static public function music(key:String):Sound
	{
		var file:String = modsMusic(key);

		if (!FileSystem.exists(file))
			file = getPath('music/$key.$SOUND_EXT');

		if (!customSoundsLoaded.exists(file))
			customSoundsLoaded.set(file, Sound.fromFile(file));

		return customSoundsLoaded.get(file);
	}

	inline static public function voices(song:String):Sound
	{
		return returnSongFile('${song.toLowerCase().replace('-', ' ')}/Voices');
	}

	inline static public function inst(song:String):Sound
	{
		return returnSongFile('${song.toLowerCase().replace('-', ' ')}/Inst');
	}

	inline static public function returnSongFile(file:String):Sound
	{
		var path:String = mods('songs/$file.$SOUND_EXT');

		if (!FileSystem.exists(path))
			path = getPath('songs/$file.$SOUND_EXT');

		if (!customSoundsLoaded.exists(path))
		{
			customSoundsLoaded.set(path, Sound.fromFile(path));
		}

		return customSoundsLoaded.get(path);
	}

	public static function image(key:String):FlxGraphic
	{
		return addCustomGraphic(key);
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		if (!ignoreMods && FileSystem.exists(mods(key)))
			return File.getContent(mods(key));

		if (FileSystem.exists(getPath(key)))
			return File.getContent(getPath(key));

		return Assets.getText(getPath(key));
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function exists(key:String)
	{
		return FileSystem.exists(mods(key)) || FileSystem.exists(getPath(key));
	}

	inline static public function getSparrowAtlas(key:String)
	{
		var imageLoaded:FlxGraphic = addCustomGraphic(key);
		var xmlExists:Bool = FileSystem.exists(modsXml(key));

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(modsXml(key)) : File.getContent(getPath('images/$key.xml'))));
	}

	inline static public function getPackerAtlas(key:String)
	{
		var imageLoaded:FlxGraphic = addCustomGraphic(key);
		var txtExists:Bool = FileSystem.exists(modsTxt(key));

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key)),
			(txtExists ? File.getContent(modsTxt(key)) : getPath('images/$key.txt')));
	}

	inline static public function formatToSongPath(path:String)
	{
		return path.toLowerCase().replace('-', ' ');
	}

	static function addCustomGraphic(key:String):FlxGraphic
	{
		var path:String = modsImages(key);

		if (!FileSystem.exists(path))
			path = getPath('images/$key.png');

		if (!customImagesLoaded.exists(key))
		{
			var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, key, false);
			newGraphic.persist = true;
			customImagesLoaded.set(key, newGraphic);

			if (!garbageAssets.contains(path))
				garbageAssets.push(path);
		}

		var graphic:FlxGraphic = customImagesLoaded.get(key);
		if (graphic != null)
			return graphic;

		trace('$key was not found and returned null!');
		return null;
	}

	static public function mods(key:String)
	{
		for (i in modFolders)
			if (FileSystem.exists('mods/$i/$key'))
				return 'mods/$i/$key';

		return 'mods/' + key;
	}

	inline static public function modsJson(key:String)
	{
		return mods('songs/' + key + '.json');
	}

	inline static public function modsVideo(key:String)
	{
		return mods('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsMusic(key:String)
	{
		return mods('music/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSounds(key:String)
	{
		return mods('sounds/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSongs(key:String)
	{
		return mods('songs/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String)
	{
		return mods('images/' + key + '.png');
	}

	inline static public function modsXml(key:String)
	{
		return mods('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String)
	{
		return mods('images/' + key + '.txt');
	}
}
