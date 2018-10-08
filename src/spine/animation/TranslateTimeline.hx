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

import spine.Bone;
import spine.Event;
import spine.Skeleton;

class TranslateTimeline extends CurveTimeline
{
	public static inline var ENTRIES: Int = 3;
	
	private static inline var PREV_TIME: Int = -3;
	private static inline var PREV_X: Int = -2;
	private static inline var PREV_Y: Int = -1;
	private static inline var X: Int = 1;
	private static inline var Y: Int = 2;

	public var boneIndex: Int;
	public var frames: Array<Float>;  // time, value, value, ...  

	public function new(frameCount: Int)
	{
		super(frameCount);
		frames = [];
		
		type = TimelineType.TRANSLATE;
	}

	override public function getPropertyId(): Int 
	{
		var value: Int = TimelineType.TRANSLATE;
		return (value << 24) + boneIndex;
	}
	
	/** Sets the time and value of the specified keyframe. */
	public function setFrame(frameIndex: Int, time: Float, x: Float, y: Float): Void
	{
		frameIndex *= ENTRIES;
		frames[frameIndex] = time;
		frames[frameIndex + X] = x;
		frames[frameIndex + Y] = y;
	}

	override public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{
		var bone: Bone = skeleton.bones[boneIndex];
		if (time < frames[0]) 
		{
			if (setupPose) 
			{
				bone.x = bone.data.x;
				bone.y = bone.data.y;
			}
			return;
		}
		
		var x: Float;
		var y: Float;
		if (time >= frames[frames.length - ENTRIES]) // Time is after last frame.
		{ 
			x = frames[frames.length + PREV_X];
			y = frames[frames.length + PREV_Y];
		} 
		else 
		{
			// Interpolate between the previous frame and the current frame.
			var frame: Int = Animation.binarySearch(frames, time, ENTRIES);
			x = frames[frame + PREV_X];
			y = frames[frame + PREV_Y];
			var frameTime: Float = frames[frame];
			var percent: Float = getCurvePercent(Math.floor(frame / ENTRIES) - 1, 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

			x += (frames[frame + X] - x) * percent;
			y += (frames[frame + Y] - y) * percent;
		}
		
		if (setupPose) 
		{
			bone.x = bone.data.x + x * alpha;
			bone.y = bone.data.y + y * alpha;
		} 
		else 
		{
			bone.x += (bone.data.x + x - bone.x) * alpha;
			bone.y += (bone.data.y + y - bone.y) * alpha;
		}
	}
}