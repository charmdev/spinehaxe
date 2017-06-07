package spine.data;

import spine.Maybe;

typedef TPath = {
	var name: String;
	var order: Maybe<Float>;
	var bones: Array<String>;
	var target: String;
	
	var positionMode: Maybe<String>;
	var spacingMode: Maybe<String>;
	var rotateMode: Maybe<String>;
	
	var rotation: Maybe<Float>;
	var position: Maybe<Float>;
	var spacing: Maybe<Float>;
	
	var rotateMix: Maybe<Float>;
	var translateMix: Maybe<Float>;
}