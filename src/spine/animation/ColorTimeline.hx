/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 * 
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 * 
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 * 
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine.animation;

import spine.animation.CurveTimeline;

import spine.Event;
import spine.Skeleton;
import spine.Slot;

class ColorTimeline extends CurveTimeline
{
	public static inline var ENTRIES: Int = 5;
	
	private static inline var PREV_TIME: Int = -5;
	private static inline var PREV_R: Int = -4;
	private static inline var PREV_G: Int = -3;
	private static inline var PREV_B: Int = -2;
	private static inline var PREV_A: Int = -1;
	private static inline var R: Int = 1;
	private static inline var G: Int = 2;
	private static inline var B: Int = 3;
	private static inline var A: Int = 4;

	public var slotIndex: Int;
	public var frames: Array<Float>;  // time, r, g, b, a, ...  

	public function new(frameCount: Int)
	{
		super(frameCount);
		frames = new Array<Float>();
		
		type = TimelineType.COLOR;
	}

	override public function getPropertyId(): Int 
	{
		var value: Int = TimelineType.COLOR;
		return (value << 24) + slotIndex;
	}
	
	/** Sets the time and value of the specified keyframe. */
	public function setFrame(frameIndex: Int, time: Float, r: Float, g: Float, b: Float, a: Float): Void
	{
		frameIndex *= ENTRIES;
		frames[frameIndex] = time;
		frames[frameIndex + R] = r;
		frames[frameIndex + G] = g;
		frames[frameIndex + B] = b;
		frames[frameIndex + A] = a;
	}

	override public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{
		var slot: Slot = skeleton.slots[slotIndex];
		if (time < frames[0]) 
		{
			if (setupPose) 
			{
				slot.r = slot.data.r;
				slot.g = slot.data.g;
				slot.b = slot.data.b;
				slot.a = slot.data.a;	
			}
			
			return;
		}

		var r: Float;
		var g: Float;
		var b: Float;
		var a: Float;
		
		if (time >= frames[frames.length - ENTRIES]) // Time is after last frame.
		{
			var i: Int = frames.length;
			r = frames[i + PREV_R];
			g = frames[i + PREV_G];
			b = frames[i + PREV_B];
			a = frames[i + PREV_A];
		}
		else 
		{
			// Interpolate between the previous frame and the current frame.
			var frame: Int = Animation.binarySearch(frames, time, ENTRIES);
			r = frames[frame + PREV_R];
			g = frames[frame + PREV_G];
			b = frames[frame + PREV_B];
			a = frames[frame + PREV_A];
			var frameTime: Float = frames[frame];
			var percent: Float = getCurvePercent(Math.floor(frame / ENTRIES - 1), 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

			r += (frames[frame + R] - r) * percent;
			g += (frames[frame + G] - g) * percent;
			b += (frames[frame + B] - b) * percent;
			a += (frames[frame + A] - a) * percent;
		}
		
		if (alpha == 1) 
		{
			slot.r = r;
			slot.g = g;
			slot.b = b;
			slot.a = a;
		}
		else 
		{
			if (setupPose) 
			{
				slot.r = slot.data.r;
				slot.g = slot.data.g;
				slot.b = slot.data.b;
				slot.a = slot.data.a;				 
			}
			
			slot.r += (r - slot.r) * alpha;
			slot.g += (g - slot.g) * alpha;
			slot.b += (b - slot.b) * alpha;
			slot.a += (a - slot.a) * alpha;		
		}
	}
}