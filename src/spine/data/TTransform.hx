package spine.data;

import spine.Maybe;

typedef TTransform = {
	var name: String;
	var order: Maybe<Float>;
	var bones: Array<String>;
	var target: String;
	
	var x: Maybe<Float>;
	var y: Maybe<Float>;
	var rotation: Maybe<Float>;
	var scaleX: Maybe<Float>;
	var scaleY: Maybe<Float>;
	var shearY: Maybe<Float>;
	
	var rotateMix: Maybe<Float>;
	var translateMix: Maybe<Float>;
	var scaleMix: Maybe<Float>;
	var shearMix: Maybe<Float>;
}