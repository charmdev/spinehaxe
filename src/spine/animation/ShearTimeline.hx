package spine.animation;

import spine.Bone;
import spine.Event;
import spine.Skeleton;
import spine.animation.TranslateTimeline;

class ShearTimeline extends TranslateTimeline
{
	public function new(frameCount: Int)
	{
		super(frameCount);
		
		type = TimelineType.SHEAR;
	}
	
	override public function getPropertyId(): Int 
	{
		var value: Int = TimelineType.SHEAR;
		return (value << 24) + boneIndex;
	}
	
	override public function apply(skeleton: Skeleton, lastTime: Float, time: Float, firedEvents: Array<Event>, alpha: Float, setupPose: Bool, mixingOut: Bool): Void
	{
		var bone: Bone = skeleton.bones[boneIndex];
		
		if (time < frames[0]) 
		{
			if (setupPose) 
			{
				bone.shearX = bone.data.shearX;
				bone.shearY = bone.data.shearY;
			}
			
			return;
		}

		var x: Float; 
		var y: Float;
		if (time >= frames[frames.length - TranslateTimeline.ENTRIES]) // Time is after last frame.
		{ 
			x = frames[frames.length + TranslateTimeline.PREV_X];
			y = frames[frames.length + TranslateTimeline.PREV_Y];
		} 
		else 
		{
			// Interpolate between the previous frame and the current frame.
			var frame: Int = Animation.binarySearch(frames, time, TranslateTimeline.ENTRIES);
			x = frames[frame + TranslateTimeline.PREV_X];
			y = frames[frame + TranslateTimeline.PREV_Y];
			var frameTime: Float = frames[frame];
			var percent: Float = getCurvePercent(Math.floor(frame / TranslateTimeline.ENTRIES) - 1, 1 - (time - frameTime) / (frames[frame + TranslateTimeline.PREV_TIME] - frameTime));

			x = x + (frames[frame + TranslateTimeline.X] - x) * percent;
			y = y + (frames[frame + TranslateTimeline.Y] - y) * percent;
		}
		if (setupPose) 
		{
			bone.shearX = bone.data.shearX + x * alpha;
			bone.shearY = bone.data.shearY + y * alpha;
		} 
		else 
		{
			bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
			bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
		}
	}
}