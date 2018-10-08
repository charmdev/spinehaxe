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
import spine.PathConstraint;
import spine.Skeleton;

class PathConstraintPositionTimeline extends CurveTimeline
{
	public static inline var ENTRIES: Int = 2;
	
	public static inline var PREV_TIME: Int = -2;
	public static inline var PREV_VALUE: Int = -1;
	public static inline var VALUE: Int = 1;

	public var pathConstraintIndex: Int;
	public var frames: Array<Float>;  // time, position, ...  

	public function new(frameCount: Int)
	{
		super(frameCount);
		frames = [];
		
		type = TimelineType.PATH_CONSTRAINT_POSITION;
	}
	
	override public function getPropertyId(): Int 
	{
		var value: Int = TimelineType.PATH_CONSTRAINT_POSITION;
		return (value << 24) + pathConstraintIndex;
	}
	
	/** Sets the time and value of the specified keyframe. */
	public function setFrame(frameIndex: Int, time: Float, value: Float): Void
	{
		frameIndex *= ENTRIES;
		frames[frameIndex] = time;
		frames[frameIndex + VALUE] = value;
	}

	override public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{
		var constraint: PathConstraint = skeleton.pathConstraints[pathConstraintIndex];
		if (time < frames[0]) 
		{
			if (setupPose) 
				constraint.position = constraint.data.position;
			
			return;
		}

		var position: Float;
		if (time >= frames[frames.length - ENTRIES]) // Time is after last frame.
			position = frames[frames.length + PREV_VALUE];
		else 
		{
			// Interpolate between the previous frame and the current frame.
			var frame: Int = Animation.binarySearch(frames, time, ENTRIES);
			position = frames[frame + PREV_VALUE];
			var frameTime: Float = frames[frame];
			var percent: Float = getCurvePercent(Math.floor(frame / ENTRIES) - 1, 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

			position += (frames[frame + VALUE] - position) * percent;
		}
		if (setupPose)
			constraint.position = constraint.data.position + (position - constraint.data.position) * alpha;
		else
			constraint.position += (position - constraint.position) * alpha;
	}
}