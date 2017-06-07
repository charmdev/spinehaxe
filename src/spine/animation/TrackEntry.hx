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

import spine.Poolable;

class TrackEntry implements Poolable
{
	public var animation: Animation;
	public var next: TrackEntry;
	public var mixingFrom: TrackEntry;
	
	public var onStart: Array<TrackEntry->Void>;
	public var onInterrupt: Array<TrackEntry->Void>;
	public var onEnd: Array<TrackEntry->Void>;
	public var onDispose: Array<TrackEntry->Void>;
	public var onComplete: Array<TrackEntry->Void>;
	public var onEvent: Array<TrackEntry->Event->Void>;
	
	public var trackIndex: Int;
	public var loop: Bool;
	public var eventThreshold: Float;
	public var attachmentThreshold: Float;
	public var drawOrderThreshold: Float;
	public var animationStart: Float;
	public var animationEnd: Float;
	public var animationLast: Float;
	public var nextAnimationLast: Float;
	public var delay: Float;
	public var trackTime: Float;
	public var trackLast: Float; 
	public var nextTrackLast: Float; 
	public var trackEnd: Float; 
	public var timeScale: Float;
	public var alpha: Float; 
	public var mixTime: Float; 
	public var mixDuration: Float; 
	public var mixAlpha: Float;
	public var timelinesFirst: Array<Bool>;
	public var timelinesRotation: Array<Float>;
	
	public function new()
	{
		onStart = [];
		onInterrupt = [];
		onEnd = [];
		onDispose = [];
		onComplete = [];
		onEvent = [];
		
		timelinesFirst = [];
		timelinesRotation = [];
	}

	public function getAnimationTime(): Float 
	{
		if (loop) 
		{
			var duration: Float = animationEnd - animationStart;
			if (duration == 0) 
				return animationStart;
			
			return (trackTime % duration) + animationStart;
		}
		
		return Math.min(trackTime + animationStart, animationEnd);
	}
	
	public function reset(): Void 
	{
		next = null;
		mixingFrom = null;
		animation = null;
		onStart = [];
		onInterrupt = [];
		onEnd = [];
		onDispose = [];
		onComplete = [];
		onEvent = [];
		timelinesFirst = [];
		timelinesRotation = [];
	}
	
	public function resetRotationDirection(): Void 
	{
		timelinesRotation = [];
	}
}