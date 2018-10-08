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


import spine.Event;
import spine.IkConstraint;
import spine.Skeleton;

class IkConstraintTimeline extends CurveTimeline
{
	public static inline var ENTRIES: Int = 3;
	
	private static inline var PREV_TIME: Int = -3;
	private static inline var PREV_MIX: Int = -2;
	private static inline var PREV_BEND_DIRECTION: Int = -1;
	private static inline var MIX: Int = 1;
	private static inline var BEND_DIRECTION: Int = 2;

	public var ikConstraintIndex: Int;
	public var frames: Array<Float>;  // time, mix, bendDirection, ...  

	public function new(frameCount: Int)
	{
		super(frameCount);
		frames = [];
		
		type = TimelineType.IK_CONSTRAINT;
	}

	override public function getPropertyId(): Int 
	{
		var value: Int = TimelineType.IK_CONSTRAINT;
		return (value << 24) + ikConstraintIndex;
	}
	
	/** Sets the time, mix and bend direction of the specified keyframe. */
	public function setFrame(frameIndex: Int, time: Float, mix: Float, bendDirection: Int): Void
	{
		frameIndex *= ENTRIES;
		frames[frameIndex] = time;
		frames[frameIndex + MIX] = mix;
		frames[frameIndex + BEND_DIRECTION] = bendDirection;
	}

	override public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{
		var constraint: IkConstraint = skeleton.ikConstraints[ikConstraintIndex];
		if (time < frames[0]) 
		{
			if (setupPose) 
			{
				constraint.mix = constraint.data.mix;
				constraint.bendDirection = constraint.data.bendDirection;
			}
			return;
		}
		
		if (time >= frames[frames.length - ENTRIES]) // Time is after last frame.
		{
			if (setupPose) 
			{
				constraint.mix = constraint.data.mix + (frames[frames.length + PREV_MIX] - constraint.data.mix) * alpha;
				constraint.bendDirection = mixingOut ? constraint.data.bendDirection : Math.floor(frames[frames.length + PREV_BEND_DIRECTION]);
			} 
			else 
			{
				constraint.mix += (frames[frames.length + PREV_MIX] - constraint.mix) * alpha;
				if (!mixingOut) 
					constraint.bendDirection = Math.floor(frames[frames.length + PREV_BEND_DIRECTION]);
			}
			return;
		}    
		
		// Interpolate between the previous frame and the current frame.
		var frame: Int = Animation.binarySearch(frames, time, ENTRIES);
		var mix: Float = frames[frame + PREV_MIX];
		var frameTime: Float = frames[frame];
		var percent: Float = getCurvePercent(Math.floor(frame / ENTRIES - 1), 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

		if (setupPose) 
		{
			constraint.mix = constraint.data.mix + (mix + (frames[frame + MIX] - mix) * percent - constraint.data.mix) * alpha;
			constraint.bendDirection = mixingOut ? constraint.data.bendDirection : Math.floor(frames[frame + PREV_BEND_DIRECTION]);
		}
		else
		{
			constraint.mix += (mix + (frames[frame + MIX] - mix) * percent - constraint.mix) * alpha;
			if (!mixingOut) 
				constraint.bendDirection = Math.floor(frames[frame + PREV_BEND_DIRECTION]);
		}
	}
}