package spine.data;

import haxe.DynamicAccess;
import spine.Maybe;

typedef TAnimation = DynamicAccess<TTimeLine>;
typedef TTimeLine = Array<TTimeLineValue>;

typedef TAnimationData = {
	var slots: DynamicAccess<TAnimation>;
	var bones: DynamicAccess<TAnimation>;
	var ik: TAnimation;
	var transform: TAnimation;
	var paths: DynamicAccess<TAnimation>;
	var deform: DynamicAccess<DynamicAccess<TAnimation>>;
	@:optional var drawOrder: TTimeLine;
	@:optional var draworder: TTimeLine;
	@:optional var events: TTimeLine;
}
 
typedef TTimeLineValue = {
	var time: Float;
	@:optional var curve: Dynamic;
}

typedef TColorTimeLineValue = {
	> TTimeLineValue,
	var color: String;
}

typedef TAttachmentTimeLineValue = {
	> TTimeLineValue,
	var name: String;
}

typedef TRotateTimeLineValue = {
	> TTimeLineValue,
	var angle: Float;
}

typedef TTranslateTimeLineValue = {
	> TTimeLineValue,
	var x: Maybe<Float>;
	var y: Maybe<Float>;
}

typedef IkConstraintTimeLineValue = {
	> TTimeLineValue,
	var mix: Maybe<Float>;
	var bendPositive: Null<Int>;
}

typedef TransformConstraintTimeLineValue = {
	> TTimeLineValue,
	var rotateMix: Maybe<Float>;
	var translateMix: Maybe<Float>;
	var scaleMix: Maybe<Float>;
	var shearMix: Maybe<Float>;
}

typedef TPathConstraintTimeLineValue = {
	> TTimeLineValue,
	var position: Maybe<Float>;
	var spacing: Maybe<Float>;
}

typedef TPathConstraintMixTimeLineValue = {
	> TTimeLineValue,
	var rotateMix: Maybe<Float>;
	var translateMix: Maybe<Float>;
}

typedef TDeformTimeLineValue = {
	> TTimeLineValue,
	@:optional var vertices: Array<Float>;
	var offset: Maybe<Float>;
}

typedef TDrawOrderTimeLineValue = {
	> TTimeLineValue,
	@:optional var offsets: Array<TDrawOrderOffset>;
}

typedef TEventTimeLineValue = {
	> TTimeLineValue,
	var name: String;
	var int: Maybe<Int>;
	var float: Maybe<Float>;
	var string: Maybe<String>;
}

typedef TDrawOrderOffset = {
	var slot: String;
	var offset: Int;
}