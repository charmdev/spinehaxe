package spine.data;

import spine.Maybe;

typedef TAttachment = {
	var name: Maybe<String>;
	var type: Maybe<String>;
	var path: Maybe<String>;
	
	var x: Maybe<Float>;
	var y: Maybe<Float>;
	var scaleX: Maybe<Float>;
	var scaleY: Maybe<Float>;
	var rotation: Maybe<Float>;
	var width: Maybe<Float>;
	var height: Maybe<Float>;
	@:optional var color: String;
	
	@:optional var parent: String;
	var skin: String;
	
	var deform: Maybe<Bool>;
	
	var vertices: Array<Float>;
	var uvs: Array<Float>;
	var triangles: Array<Int>;
	
	var hull: Maybe<Int>;
	@:optional var edges: Array<Int>;
	
	var vertexCount: Maybe<Int>;
	
	var closed: Maybe<Bool>;
	var constantSpeed: Maybe<Bool>;
	@:optional var lengths: Array<Float>;
}