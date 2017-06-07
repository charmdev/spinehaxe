package spine.data;

import haxe.DynamicAccess;
import spine.data.TEvent.TEvents;
import spine.data.TAnimation.TAnimationData;

typedef TSpineData = {
	var skeleton: TSkeleton;
	var bones: Array<TBone>;
	var slots: Array<TSlot>;
	var ik: Array<TIk>;
	var transform: Array<TTransform>;
	var path: Array<TPath>;
	var skins: TSkins;
	var events: TEvents;
	var animations: DynamicAccess<TAnimationData>;
}