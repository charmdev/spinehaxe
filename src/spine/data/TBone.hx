package spine.data;

import spine.Maybe;

typedef TBone = {
	var name: String;	
	@:optional var parent: String;
	var length: Maybe<Float>;
	var x: Maybe<Float>;
	var y: Maybe<Float>;
	var rotation: Maybe<Float>;
	var scaleX: Maybe<Float>;
	var scaleY: Maybe<Float>;
	var shearX: Maybe<Float>;
	var shearY: Maybe<Float>;
	var transform: Maybe<String>;
}