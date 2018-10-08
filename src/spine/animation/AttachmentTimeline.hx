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
import spine.Skeleton;
import spine.animation.Timeline;

class AttachmentTimeline implements Timeline
{
	public var type:TimelineType;
	
	public var frameCount(get, never): Int;

	public var slotIndex: Int;
	public var frames: Array<Float>;  // time, ...  
	public var attachmentNames: Array<String>;

	public function new(frameCount: Int)
	{
		frames = [];
		attachmentNames = [];
		
		type = TimelineType.ATTACHMENT;
	}
	
	public inline function getPropertyId(): Int 
	{
		var value: Int = TimelineType.ATTACHMENT;
		return (value << 24) + slotIndex;
	}
	
	/** Sets the time and value of the specified keyframe. */
	public inline function setFrame(frameIndex: Int, time: Float, attachmentName: String): Void
	{
		frames[frameIndex] = time;
		attachmentNames[frameIndex] = attachmentName;
	}

	public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{
		var attachmentName: String;
		var slot: Slot = skeleton.slots[slotIndex];
		if (mixingOut && setupPose) 
		{			
			attachmentName = slot.data.attachmentName;
			slot.attachment = (attachmentName == null) ? null : skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName);
			return;
		}
		
		if (time < frames[0]) 
		{
			if (setupPose) 
			{
				attachmentName = slot.data.attachmentName;
				slot.attachment = (attachmentName == null) ? null : skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName);
			}
			
			return;
		}
		
		var frameIndex: Int;
		if (time >= frames[frames.length - 1]) // Time is after last frame.
			frameIndex = frames.length - 1;
		else
			frameIndex = Animation.binarySearch(frames, time, 1) - 1;

		attachmentName = attachmentNames[frameIndex];
		skeleton.slots[slotIndex].attachment = (attachmentName == null) ? null : skeleton.getAttachmentForSlotIndex(slotIndex, attachmentName);
	}
	
	// getters / setters
	
	private inline function get_frameCount(): Int
	{
		return frames.length;
	}
}