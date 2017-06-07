/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine.flash;

import flash.display.Bitmap;
import flash.display.BitmapData;
import haxe.DynamicAccess;

import spine.atlas.AtlasPage;
import spine.atlas.AtlasRegion;
import spine.atlas.TextureLoader;

class FlashTextureLoader implements TextureLoader 
{
	public var bitmapDatas: Dynamic;
	public var singleBitmapData: BitmapData;

	/** @param bitmaps A Bitmap or BitmapData for an atlas that has only one page, or for a multi page atlas an object where the
	 * key is the image path and the value is the Bitmap or BitmapData. */
	public function new(bitmaps: Dynamic)
	{
		bitmapDatas = {};
		
		if (Std.is(bitmaps, BitmapData)) 
		{
			singleBitmapData = cast(bitmaps, BitmapData);
			return;
		}
		if (Std.is(bitmaps, Bitmap)) 
		{
			singleBitmapData = cast(bitmaps, Bitmap).bitmapData;
			return;
		}
		
		for (field in Reflect.fields(bitmaps)) 
		{
			var object: Dynamic = Reflect.field(field, bitmaps);
			
			var bitmapData: BitmapData;
			if (Std.is(object, BitmapData))
				bitmapData = cast(object, BitmapData);
			else if (Std.is(object, Bitmap))
				bitmapData = cast(object, Bitmap).bitmapData;
			else
				throw "Object for path \"" + field + "\" must be a Bitmap or BitmapData: " + object;
			
			Reflect.setField(bitmapDatas, field, bitmapData);
		}
	}

	public function loadPage(page: AtlasPage, path: String): Void 
	{
		var bitmapData: BitmapData = (singleBitmapData != null) ? singleBitmapData : cast Reflect.field(bitmapDatas, path);
		
		if (bitmapData == null)
			throw "BitmapData not found with name: " + path;
		
		page.rendererObject = bitmapData;
		page.width = bitmapData.width;
		page.height = bitmapData.height;
	}
	
	public function loadRegion (region: AtlasRegion): Void 
	{

	}

	public function unloadPage (page: AtlasPage): Void 
	{
		cast (page.rendererObject, BitmapData).dispose();
	}
}
