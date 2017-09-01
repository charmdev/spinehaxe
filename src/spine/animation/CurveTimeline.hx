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

import haxe.ds.Vector;
import spine.animation.Timeline;

import spine.MathUtils;
import spine.Event;
import spine.Skeleton;

/** Base class for frames that use an interpolation bezier curve. */
class CurveTimeline implements Timeline
{
	public var frameCount(get, never): Int;

	private static inline var LINEAR: Float = 0;
	private static inline var STEPPED: Float = 1;
	private static inline var BEZIER: Float = 2;
	private static var BEZIER_SIZE: Int = 10 * 2 - 1;

	private var curves: Vector<Float>;  // type, x, y, ...  

	public function new(frameCount: Int)
	{
		curves = ArrayUtils.allocFloat((frameCount - 1) * BEZIER_SIZE);
	}
	
	public function getPropertyId (): Int 
	{
		return 0;
	}
	
	public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{

	}

	private inline function get_frameCount(): Int
	{
		return Math.floor(curves.length / BEZIER_SIZE + 1);
	}

	public inline function setLinear(frameIndex: Int): Void
	{
		curves[frameIndex * BEZIER_SIZE] = LINEAR;
	}

	public inline function setStepped(frameIndex: Int): Void
	{
		curves[frameIndex * BEZIER_SIZE] = STEPPED;
	}

	/** Sets the control handle positions for an interpolation bezier curve used to transition from this keyframe to the next.
	* cx1 and cx2 are from 0 to 1, representing the percent of time between the two keyframes. cy1 and cy2 are the percent of
	* the difference between the keyframe's values. */
	public function setCurve(frameIndex: Int, cx1: Float, cy1: Float, cx2: Float, cy2: Float): Void
	{
		var tmpx: Float = (-cx1 * 2 + cx2) * 0.03;
		var tmpy: Float = (-cy1 * 2 + cy2) * 0.03;
		var dddfx: Float = ((cx1 - cx2) * 3 + 1) * 0.006;
		var dddfy: Float = ((cy1 - cy2) * 3 + 1) * 0.006;
		var ddfx: Float = tmpx * 2 + dddfx;
		var ddfy: Float = tmpy * 2 + dddfy;
		var dfx: Float = cx1 * 0.3 + tmpx + dddfx * 0.16666667;
		var dfy: Float = cy1 * 0.3 + tmpy + dddfy * 0.16666667;

		var i: Int = frameIndex * BEZIER_SIZE;
		//var curves: Array<Float> = this.curves;
		curves[i++] = BEZIER;

		var x : Float = dfx;
		var y : Float = dfy;
		var n : Int = i + BEZIER_SIZE - 1;
		while (i < n)
		{
			curves[i] = x;
			curves[i + 1] = y;
			dfx += ddfx;
			dfy += ddfy;
			ddfx += dddfx;
			ddfy += dddfy;
			x += dfx;
			y += dfy;
			i += 2;
		}
	}

	public function getCurvePercent(frameIndex: Int, percent: Float): Float
	{
		percent = MathUtils.clamp(percent, 0, 1);
		//var curves: Array<Float> = this.curves;
		var i: Int = frameIndex * BEZIER_SIZE;
		var type: Float = curves[i];
		if (type == LINEAR)
			return percent;

		if (type == STEPPED)
			return 0;
		
		i++;
		var x: Float = 0;
		var start: Int = i;
		var n: Int = i + BEZIER_SIZE - 1;
		while (i < n)
		{
			x = curves[i];
			if (x >= percent) 
			{
				var prevX: Float;
				var prevY: Float;
				if (i == start) 
				{
					prevX = 0;
					prevY = 0;
				}
				else
				{
					prevX = curves[i - 2];
					prevY = curves[i - 1];
				}
				return prevY + (curves[i + 1] - prevY) * (percent - prevX) / (x - prevX);
			}
			i += 2;
		}
		var y: Float = curves[i - 1];
		return y + (1 - y) * (percent - x) / (1 - x);
	}
}